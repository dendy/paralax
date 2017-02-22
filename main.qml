
import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.2

Window {
	id: self

	width: 600
	height: 600

	RowLayout {
		anchors.fill: parent
		anchors.margins: 10

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true

			Item {
				id: colorItem

				Layout.fillWidth: true
				Layout.fillHeight: true

				Component {
					id: point
					Item {
						Image {
							anchors.centerIn: parent
							width: 40
							height: width
							source: "star.png"
						}
					}
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
					fragmentShader: "
						varying vec2 qt_TexCoord0;
						uniform sampler2D src;
						uniform sampler2D base;
						void main() {
							gl_FragColor = texture2D(base, qt_TexCoord0) + texture2D(src, qt_TexCoord0);
						}
					"
				}
				live: false
				recursive: true
				textureSize: Qt.size(256, 256)

				MouseArea {
					anchors.fill: parent

					property var points: []

					function addb(x, y) {
						var p = point.createObject(colorItem);
						p.x = Qt.binding(function() {return colorItem.width*x});
						p.y = Qt.binding(function() {return colorItem.height*y});
						points.push(p);
					}

					function paint(mouse) {
						for (var p in points) points[p].destroy();
						points = [];
						points.push(point.createObject(colorItem, {x: mouse.x, y: mouse.y}));
						colorFbo.scheduleUpdate();
					}

					onPressed: paint(mouse);
					onPositionChanged: paint(mouse);

					Component.onCompleted: {
						addb(0.2, 0.3);
						addb(0.6, 0.7);
						addb(0.3, 0.4);
						addb(0.8, 0.3);
						addb(0.9, 0.8);
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

					Button {
						text: "Update"
						onClicked: colorFbo.scheduleUpdate();
					}

					Item {
						Layout.fillHeight: true
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
					running: true
				}
				property real radangle: angle * Math.PI / 180.0

				property var src: colorFbo
				property real ascend: 5.0
				property point pos: Qt.point(0.5 + Math.sin(radangle) * 0.3, 0.5 + Math.cos(radangle) * 0.3)
				property int samples: 50
				property point fragSize: Qt.point(1.0/colorFbo.textureSize.width, 1.0/colorFbo.textureSize.height)

				fragmentShader: "
					varying vec2 qt_TexCoord0;
					uniform sampler2D src;
					uniform float ascend;
					uniform vec2 pos;
					uniform int samples;
					uniform vec2 fragSize;

					void main() {
						mediump vec2 dir = normalize(pos - qt_TexCoord0);
						mediump float fullDist = distance(pos, qt_TexCoord0);
						mediump float dist = fullDist / ascend;
						mediump float shadow = smoothstep(0.1, 0.7, fullDist);
						mediump float rangeStep = fragSize.x * 0.5;
						for (float range = rangeStep; range < dist; range += rangeStep) {
							mediump float step = range / dist;
							lowp float a = texture2D(src, qt_TexCoord0 + dist * dir * step).a;
							shadow = max(shadow, a / step);
							if (shadow >= 1.0) break;
						}
						mediump float alpha = smoothstep(0.8, 1.0, shadow);
						lowp vec4 c = texture2D(src, qt_TexCoord0);
						gl_FragColor = mix(c, vec4(vec3(0.0), 1.0), alpha * 0.2);
					}
				"
			}
		}
	}
}
