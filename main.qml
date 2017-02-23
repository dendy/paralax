
import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3

Window {
	id: self

	width: 800
	height: 600

	property QtObject config: QtObject {
		property size colorMapSize: Qt.size(controls.colorMapSize, controls.colorMapSize)
		property size lightMapSize: Qt.size(controls.lightMapSize, controls.lightMapSize)
		property size specularMapSize: Qt.size(controls.specularMapSize, controls.specularMapSize)
	}

	property QtObject global: QtObject {
		property var addLight: self.scene.addLight
		property var removeLight: self.scene.removeLight
		property var controls: controls
	}

	property LightRenderer light: LightRenderer {
		id: renderer

		ambient: '#5f2040'

		softness: controls.softness
		specular: controls.specular
		ascend: controls.ascend
		heightMap: self.colorMap
		lightMapSize: self.config.lightMapSize
		specularMapSize: self.config.specularMapSize
		samples: controls.samples
	}

	property Scene scene: Scene {
		animate: controls.animate
		lightModel: renderer.model
	}

	property alias colorMap: editor.colorMap

	RowLayout {
		anchors.fill: parent
		anchors.margins: 10

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true

			Item {
				Layout.fillWidth: true
				Layout.fillHeight: true

				ShaderEffect {
					anchors.centerIn: parent
					width: Math.min(parent.width, parent.height)
					height: width
					property var source: renderer.normalMap
				}
			}

			Item {
				Layout.fillWidth: true
				Layout.fillHeight: true

				Editor {
					id: editor
					anchors.fill: parent
				}
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true

			Item {
				Layout.fillWidth: true
				Layout.fillHeight: true

				GridView {
					anchors.fill: parent
					model: renderer.fboModel
					cellWidth: 300
					cellHeight: cellWidth/2
					delegate: Item {
						id: self
						width: GridView.view.cellWidth
						height: GridView.view.cellHeight

						property var light: model.light

						Rectangle {
							anchors { fill: parent; margins: 2 }
							color: "#80000000"
						}

						RowLayout {
							anchors { fill: parent; margins: 4 }

							ShaderEffect {
								Layout.fillWidth: true
								Layout.fillHeight: true
								property var source: self.light ? self.light.fbo : undefined
							}

							ShaderEffect {
								Layout.fillWidth: true
								Layout.fillHeight: true
								property var source: self.light ? self.light.specularFbo : undefined
							}
						}
					}
				}
			}

			Item {
				Layout.fillWidth: true
				Layout.fillHeight: true

				ShaderEffect {
					anchors.centerIn: parent

					width: Math.min(parent.width, parent.height)
					height: width

					property var colorMap: self.colorMap
					property var lightMap: renderer.lightMap
					property var specularMap: renderer.specularMap
					property bool specular: controls.specular
					property color background: Qt.rgba(0.8, 0.6, 0.4, 1.0)

					fragmentShader: "
						varying vec2 qt_TexCoord0;
						uniform sampler2D colorMap;
						uniform sampler2D lightMap;
						uniform sampler2D specularMap;
						uniform vec4 background;
						uniform bool specular;

						void main() {
							lowp vec3 color = background.rgb + texture2D(colorMap, qt_TexCoord0).rgb;
							gl_FragColor.rgb = color * texture2D(lightMap, qt_TexCoord0).rgb;
							gl_FragColor.a = 1.0;

							if (specular) {
								lowp vec4 scolor = texture2D(specularMap, qt_TexCoord0);
								gl_FragColor.rgb = gl_FragColor.rgb * (vec3(1.0) - scolor.rgb) + scolor.rgb;
							}
						}
					"

					MouseArea {
						id: lightArea
						anchors.fill: parent
						enabled: !controls.animate

						function setPos(mouse) {
							controls.setCustomLightPos(Qt.point(mouseX/width, mouseY/height));
						}

						onPressed: setPos(mouse);
						onPositionChanged: setPos(mouse);
					}
				}
			}
		}

		Controls {
			id: controls
			Layout.preferredWidth: 300
			Layout.fillHeight: true
			lightModel: self.scene.lightModel
		}
	}
}
