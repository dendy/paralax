
import QtQuick 2.7

QtObject {
	id: self

	property color ambient: 'black'

	property real softness: 0
	property bool specular: true
	property real ascend: 1.0
	property real samples: 0.5
	property ShaderEffectSource heightMap

	property ListModel model: ListModel {
		onCountChanged: {
			self.__createLights();
		}
	}

	property ListModel fboModel: ListModel {}

	property var lightMap: ambientLight.fbo
	property var specularMap: ambientLight.specularFbo

	property size lightMapSize: Qt.size(256, 256)
	property size specularMapSize: Qt.size(256, 256)

	property var ambientLight : QtObject {
		property ShaderEffectSource fbo: ShaderEffectSource {
			textureSize: self.lightMapSize

			sourceItem: ShaderEffect {
				width: 100
				height: 100

				property color color: self.ambient

				fragmentShader: "
					uniform vec4 color;
					void main() {
						gl_FragColor = color;
					}
				"
			}
		}

		property ShaderEffectSource specularFbo: ShaderEffectSource {
			textureSize: self.specularMapSize
			sourceItem: Rectangle {
				width: 1; height: 1
				color: "transparent"
			}
		}
	}

	property Component __pointLightComponent: Component {
		id: pointLight

		QtObject {
			id: self

			property var context
			property ShaderEffectSource base
			property var specularBase
			property Light light

			property ShaderEffectSource fbo: ShaderEffectSource {
				textureSize: self.context.lightMapSize

				sourceItem: ShaderEffect {
					width: 10
					height: 10

					property var src: self.context.heightMap
					property var base: self.base
					property color color: self.light.color
					property point pos: self.light.pos
					property real size: self.light.size
					property real ascend: self.context.ascend
					property real samples: self.context.samples

					property real softness: self.context.softness

					property point fragSize: Qt.point(1.0/src.textureSize.width, 1.0/src.textureSize.height)

					// fake dependency
					property var specularMap: specularBase

					fragmentShader: "
						varying vec2 qt_TexCoord0;

						uniform sampler2D base;
						uniform sampler2D src;

						uniform vec4 color;
						uniform vec2 pos;
						uniform float size;
						uniform float ascend;
						uniform vec2 fragSize;
						uniform float softness;
						uniform float samples;

						void main() {
							lowp vec4 c = texture2D(src, qt_TexCoord0);

							mediump vec2 dir = normalize(pos - qt_TexCoord0);
							mediump float fullDist = distance(pos, qt_TexCoord0);

							mediump float localAscend = ascend - c.a;
							mediump float localHeight = 1.0 - c.a;
							mediump float dist = fullDist / localAscend;

							mediump float shadow = smoothstep(0.3*size, size, fullDist);

							if (shadow != 1.0) {
								mediump float s = c.a;
								mediump float rangeStep = fragSize.x * samples;
								for (float range = rangeStep; range < dist; range += rangeStep) {
									mediump float step = range / dist;
									lowp float a = texture2D(src, qt_TexCoord0 + dist * dir * step).a - c.a;
									s = max(s, c.a + a*localHeight/step);
									if (s >= 1.0) break;
								}
								shadow = max(shadow, smoothstep(softness, 1.0, s - c.a));
							}

							lowp float lightness = 1.0 - shadow;

							lowp vec3 dcolor = color.rgb * lightness;

							gl_FragColor.rgb = texture2D(base, qt_TexCoord0).rgb * (vec3(1.0) - dcolor) + dcolor;
							gl_FragColor.a = lightness;
						}
					"
				}
			}

			property ShaderEffectSource specularFbo: ShaderEffectSource {
				textureSize: self.context.specularMapSize

				sourceItem: ShaderEffect {
					width: 10
					height: 10

					property var heightMap: self.context.heightMap
					property var lightMap: self.fbo
					property var base: self.specularBase
					property var norm: self.context.normalMap
					property point pos: self.light.pos
					property real size: self.light.size
					property real ascend: self.context.ascend
					property color color: self.light.color

					fragmentShader: "
						varying vec2 qt_TexCoord0;

						uniform vec4 color;
						uniform sampler2D base;
						uniform sampler2D norm;
						uniform sampler2D heightMap;
						uniform sampler2D lightMap;
						uniform vec2 pos;
						uniform float size;
						uniform float ascend;

						void main() {
							lowp vec4 c = texture2D(heightMap, qt_TexCoord0);

							mediump vec3 light = normalize(vec3(qt_TexCoord0, c.a) - vec3(pos, ascend));
							mediump vec2 sn = (texture2D(norm, qt_TexCoord0).rg - vec2(0.5)) * 2.0;
							mediump vec3 n = vec3(sn, sqrt(1.0 - pow(sn.x, 2.0) - pow(sn.y, 2.0)));
							n = normalize(vec3(sn, 1.0));
							mediump vec3 ref = reflect(light, n);
							mediump float d = smoothstep(0.99, 1.0, dot(ref, vec3(0.0, 0.0, 1.0)));
							gl_FragColor = texture2D(base, qt_TexCoord0);
							if (d > 0.0) {
								gl_FragColor = mix(gl_FragColor, color, d * texture2D(lightMap, qt_TexCoord0).a);
							}
						}
					"
				}
			}
		}
	}

	function __createLights() {
		{
			for (var i = 0; i < fboModel.count; ++i) fboModel.get(i).light.destroy();
			fboModel.clear();
		}

		var baseLight = self.ambientLight;

		{
			for (var i = 0; i < self.model.count; ++i) {
				var m = self.model.get(i);
				var l = pointLight.createObject(null, {
					light: m.light,
					base: baseLight.fbo,
					specularBase: baseLight.specularFbo,
					context: self
				});
				fboModel.append({light: l});
				baseLight = l;
			}
		}

		self.lightMap = baseLight.fbo;
		self.specularMap = baseLight.specularFbo;
	}

	Component.onCompleted: {
		__createLights();
	}

	property ShaderEffectSource normalMap: ShaderEffectSource {
		sourceItem: ShaderEffect {
			width: src.width
			height: src.height

			property var src: self.heightMap
			property point fragSize: Qt.point(1.0/src.textureSize.width, 1.0/src.textureSize.height)

			fragmentShader: "
				varying vec2 qt_TexCoord0;
				uniform sampler2D src;
				uniform vec2 fragSize;
				void main() {
					mediump float x1 = texture2D(src, vec2(qt_TexCoord0.x - fragSize.x, qt_TexCoord0.y)).a;
					mediump float x2 = texture2D(src, vec2(qt_TexCoord0.x + fragSize.x, qt_TexCoord0.y)).a;
					mediump float y1 = texture2D(src, vec2(qt_TexCoord0.x, qt_TexCoord0.y - fragSize.y)).a;
					mediump float y2 = texture2D(src, vec2(qt_TexCoord0.x, qt_TexCoord0.y + fragSize.y)).a;
					mediump vec2 n = -vec2(x2 - x1, y2 - y1) * 0.5 + vec2(0.5);
					gl_FragColor = vec4(n.x, n.y, 1.0, 1.0);
				}
			"
		}
	}
}
