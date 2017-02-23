
import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.2

Window {
	id: self

	width: 600
	height: 600

	Component {
		id: point
		Item {
			id: self
			property string name: "star"
			property real iconScale: 1.0
			Image {
				anchors.centerIn: parent
				width: 40
				height: width
				source: self.name + ".png"
				opacity: 0.2
				scale: self.iconScale
			}
		}
	}

	Item {
		id: colorItem
		width: 512
		height: 512
	}

	RowLayout {
		anchors.fill: parent
		anchors.margins: 10

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true

			ShaderEffectSource {
				id: normalFbo

				Layout.fillWidth: true
				Layout.fillHeight: true

				sourceItem: ShaderEffect {
					width: colorFbo.width
					height: colorFbo.height
					property var src: colorFbo
					property point fragSize: Qt.point(1.0/colorFbo.textureSize.width, 1.0/colorFbo.textureSize.height)
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

			ShaderEffectSource {
				id: colorFbo

				Layout.fillWidth: true
				Layout.fillHeight: true

				sourceItem: ShaderEffect {
					width: colorItem.width
					height: colorItem.height
					property var src: ShaderEffectSource { sourceItem: colorItem; hideSource: true }
					property var base: colorFbo
					property bool clear: iconView.model.get(iconView.currentIndex).clear === true
					property point clearPos: Qt.point(paintArea.mouseX/paintArea.width, paintArea.mouseY/paintArea.height)
					fragmentShader: "
						varying vec2 qt_TexCoord0;
						uniform sampler2D src;
						uniform sampler2D base;
						uniform bool clear;
						uniform vec2 clearPos;
						void main() {
							if (clear) {
								gl_FragColor = distance(qt_TexCoord0, clearPos) < 0.06 ? vec4(0.0) : texture2D(base, qt_TexCoord0);
							} else {
								gl_FragColor = texture2D(base, qt_TexCoord0) + texture2D(src, qt_TexCoord0);
							}
						}
					"
				}
				live: false
				recursive: true
				textureSize: Qt.size(512, 512)

				MouseArea {
					id: paintArea

					anchors.fill: parent

					property var points: []

					function addb(x, y, name, scale) {
						var p = point.createObject(colorItem);
						p.x = Qt.binding(function() {return colorItem.width*x});
						p.y = Qt.binding(function() {return colorItem.height*y});
						p.name = name;
						p.iconScale = scale;
						points.push(p);
					}

					function paint(mouse) {
						for (var p in points) points[p].destroy();
						points = [];
						points.push(point.createObject(colorItem, {
							x: mouse.x*colorItem.width/width,
							y: mouse.y*colorItem.height/height,
							name: iconView.model.get(iconView.currentIndex).name,
							iconScale: iconScaleSlider.value
						}));
						colorFbo.scheduleUpdate();
					}

					onPressed: paint(mouse);
					onPositionChanged: paint(mouse);

					Component.onCompleted: {
						addb(0.2, 0.3, 'star', 1.5);
						addb(0.6, 0.7, 'gear', 3.0);
						addb(0.3, 0.4, 'star', 2.5);
						addb(0.8, 0.3, 'cloud', 4.0);
						addb(0.9, 0.8, 'leaf', 2.5);
						colorFbo.scheduleUpdate();
					}
				}
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true

			Item {
				Layout.fillWidth: true
				Layout.fillHeight: true

				ColumnLayout {
					anchors.fill: parent

					Row {
						Text { text: 'Softness:' }
						Slider { id: softnessSlider }
					}

					Row {
						Text { text: 'Light ascend:' }
						Slider { id: ascendSlider; minimumValue: 1.1; maximumValue: 10; value: 3 }
					}

					CheckBox { id: specular; text: "Specular"; checked: true }
					CheckBox { id: animateLight; text: "Animate light"; checked: true }

					Item {
						Layout.fillHeight: true
					}

					Row {
						Text { text: 'Icon scale' }
						Slider { id: iconScaleSlider; value: 2; minimumValue: 1; maximumValue: 5 }
					}

					ListView {
						id: iconView
						Layout.preferredHeight: 55
						Layout.fillWidth: true
						orientation: ListView.Horizontal
						model: ListModel {
							ListElement { name: "star" }
							ListElement { name: "cloud" }
							ListElement { name: "gear" }
							ListElement { name: "leaf" }
							ListElement { clear: true }
						}
						delegate: Rectangle {
							id: delegate
							height: ListView.view.height
							width: height
							radius: 10
							border.color: ListView.isCurrentItem ? "black" : "transparent"
							border.width: 2

							Image {
								anchors { fill: parent; margins: 5 }
								source: model.name ? model.name + ".png" : ''
							}

							Text {
								anchors.centerIn: parent
								text: model.clear ? "CLEAR" : ''
							}

							MouseArea {
								anchors.fill: parent
								onPressed: delegate.ListView.view.currentIndex = model.index;
							}
						}
					}
				}
			}

			ShaderEffect {
				Layout.fillWidth: true
				Layout.fillHeight: true

				property real angle: 0
				RotationAnimation on angle {
					from: 0; to: 360
					duration: 5000
					loops: Animation.Infinite
					running: animateLight.checked
				}
				property real radangle: angle * Math.PI / 180.0

				property var src: colorFbo
				property var norm: normalFbo
				property real ascend: ascendSlider.value
				property point pos: animateLight.checked ?
						Qt.point(0.5 + Math.sin(radangle) * 0.3, 0.5 + Math.cos(radangle) * 0.3) :
						Qt.point(lightArea.mouseX/lightArea.width, lightArea.mouseY/lightArea.height)
				property int samples: 50
				property point fragSize: Qt.point(1.0/colorFbo.textureSize.width, 1.0/colorFbo.textureSize.height)
				property real softness: softnessSlider.value
				property bool specular: specular.checked

				fragmentShader: "
					varying vec2 qt_TexCoord0;
					uniform sampler2D src;
					uniform sampler2D norm;
					uniform float ascend;
					uniform vec2 pos;
					uniform int samples;
					uniform vec2 fragSize;
					uniform float softness;
					uniform bool specular;

					void main() {
						lowp vec4 c = texture2D(src, qt_TexCoord0);

						mediump vec2 dir = normalize(pos - qt_TexCoord0);
						mediump float fullDist = distance(pos, qt_TexCoord0);

						mediump float localAscend = ascend - c.a;
						mediump float localHeight = 1.0 - c.a;
						mediump float dist = fullDist / localAscend;

						mediump float shadow = smoothstep(0.3, 0.7, fullDist);

						if (shadow != 1.0) {
							mediump float s = c.a;
							mediump float rangeStep = fragSize.x * 0.5;
							for (float range = rangeStep; range < dist; range += rangeStep) {
								mediump float step = range / dist;
								lowp float a = texture2D(src, qt_TexCoord0 + dist * dir * step).a - c.a;
								s = max(s, c.a + a*localHeight/step);
								if (s >= 1.0) break;
							}
							shadow = max(shadow, smoothstep(softness, 1.0, s - c.a));
						}

						mediump float alpha = shadow;
						gl_FragColor = mix(vec4(0.8, 0.6, 0.4, 1.0), vec4(vec3(0.0), 1.0), alpha * 0.4);

						if (specular) {
							mediump vec3 light = normalize(vec3(qt_TexCoord0, c.a) - vec3(pos, ascend));
							mediump vec2 sn = (texture2D(norm, qt_TexCoord0).rg - vec2(0.5)) * 2.0;
							mediump vec3 n = vec3(sn, sqrt(1.0 - pow(sn.x, 2.0) - pow(sn.y, 2.0)));
							n = normalize(vec3(sn, 1.0));
							mediump vec3 ref = reflect(light, n);
							mediump float d = smoothstep(0.99, 1.0, dot(ref, vec3(0.0, 0.0, 1.0))) * (1.0 - alpha);
							if (d > 0.0) {
								gl_FragColor = mix(gl_FragColor, vec4(1.0, 1.0, 1.0, 1.0), d);
							}
						}
					}
				"

				MouseArea {
					id: lightArea
					anchors.fill: parent
				}
			}
		}
	}
}
