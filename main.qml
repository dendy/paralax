
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

				Item {
					id: point

					Image {
						anchors.centerIn: parent
						width: 40
						height: width
						source: "star.png"
					}
				}

				MouseArea {
					anchors.fill: parent
					onPositionChanged: {
						point.x = mouse.x;
						point.y = mouse.y;
						colorFbo.scheduleUpdate();
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
					property var src: ShaderEffectSource { sourceItem: colorItem }
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
						mediump float dist = distance(pos, qt_TexCoord0) / ascend;
						mediump float shadow = 0.0;
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
