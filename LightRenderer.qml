
import QtQuick 2.7

QtObject {
	id: self

	property color ambient: 'black'

	property ShaderEffectSource heightMap

	property ListModel model: ListModel {
		onCountChanged: {
			self.__createLights();
		}
	}

	property ListModel fboModel: ListModel {}

	property var target: ambientLight.fbo

	property size fboSize: Qt.size(512, 512)

	property var ambientLight : QtObject {
		property ShaderEffectSource fbo: ShaderEffectSource {
			textureSize: self.fboSize

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
	}

	property Component __pointLightComponent: Component {
		id: pointLight

		QtObject {
			id: self

			property size fboSize
			property ShaderEffectSource base
			property Light light

			property ShaderEffectSource fbo: ShaderEffectSource {
				textureSize: self.fboSize

				sourceItem: ShaderEffect {
					width: 10
					height: 10

					property var base: self.base
					property color color: self.light.color
					property point pos: self.light.pos
					property real size: self.light.size

					fragmentShader: "
						uniform vec4 color;
						uniform vec2 pos;
						uniform float size;
						uniform sampler2D base;
						varying vec2 qt_TexCoord0;
						void main() {
							mediump float dist = distance(qt_TexCoord0, pos);
							lowp vec3 dcolor = color * (1.0 - smoothstep(size*0.3, size, dist));
							gl_FragColor.rgb = texture2D(base, qt_TexCoord0).rgb * (vec3(1.0) - dcolor) + dcolor;
							gl_FragColor.a = 1.0;
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
				var l = pointLight.createObject(null, {light: m.light, base: baseLight.fbo, fboSize: self.fboSize});
				fboModel.append({light: l});
				baseLight = l;
			}
		}

		self.target = baseLight.fbo;
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
