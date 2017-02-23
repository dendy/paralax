
import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.2

Window {
	id: self

	width: 800
	height: 600

	property size fboSize: Qt.size(1024, 1024);

	property LightRenderer light: LightRenderer {
		id: renderer

		ambient: '#7f2040'

		softness: softnessSlider.value
		specular: specularCheckBox.checked
		ascend: ascendSlider.value
		heightMap: colorFbo
		fboSize: self.fboSize

		Component.onCompleted: {
			model.append({light: redLight});
			model.append({light: greenLight});
			model.append({light: blueLight});
		}
	}

	Light {
		id: redLight
		color: '#ff80f0'
		size: 0.9

		property real angle: 0
		RotationAnimation on angle {
			from: 0; to: 360
			duration: 5000
			loops: Animation.Infinite
			running: animateLight.checked
		}
		property real radangle: angle * Math.PI / 180.0

		pos: animateLight.checked ?
				Qt.point(0.5 + Math.sin(radangle) * 0.3, 0.5 + Math.cos(radangle) * 0.3) :
				Qt.point(lightArea.mouseX/lightArea.width, lightArea.mouseY/lightArea.height)
	}

	Light {
		id: greenLight
		color: 'white'
		pos: Qt.point(0.5, 0.9)
		size: 0.4

		SequentialAnimation on color {
			ColorAnimation { duration: 5000; to: '#20ff20'; easing.type: Easing.InOutCubic }
			ColorAnimation { duration: 2000; to: '#40cc40'; easing.type: Easing.InOutExpo }
			running: animateLight.checked
			loops: Animation.Infinite
		}
	}

	Light {
		id: blueLight
		color: '#404000ff'
		pos: Qt.point(0.9, by)
		size: 0.6

		property real by
		SequentialAnimation on by {
			NumberAnimation { from: 0; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
			NumberAnimation { from: 1; to: 0; duration: 2000; easing.type: Easing.OutBounce }
			loops: Animation.Infinite
			running: animateLight.checked
		}
	}

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

				ShaderEffectSource {
					id: colorFbo

					anchors.centerIn: parent
					width: Math.min(parent.width, parent.height)
					height: width

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
					textureSize: self.fboSize

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
							anchors.fill: parent
							color: "#80000000"
						}

						RowLayout {
							anchors { fill: parent; margins: 4 }

							ShaderEffect {
								Layout.fillWidth: true
								Layout.fillHeight: true
								property var source: self.light.fbo
							}

							ShaderEffect {
								Layout.fillWidth: true
								Layout.fillHeight: true
								property var source: self.light.specularFbo
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

					property var lightMap: renderer.lightMap
					property var specularMap: renderer.specularMap
					property bool specular: specularCheckBox.checked

					fragmentShader: "
						varying vec2 qt_TexCoord0;
						uniform sampler2D lightMap;
						uniform sampler2D specularMap;
						uniform bool specular;

						void main() {
							gl_FragColor.rgb = vec3(0.8, 0.6, 0.4) * texture2D(lightMap, qt_TexCoord0).rgb;
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
					}
				}
			}
		}

		ColumnLayout {
			Layout.maximumWidth: 300
			Layout.fillHeight: true

			Row {
				Text { text: 'Softness:' }
				Slider { id: softnessSlider }
			}

			Row {
				Text { text: 'Light ascend:' }
				Slider { id: ascendSlider; minimumValue: 1.1; maximumValue: 10; value: 3 }
			}

			CheckBox { id: specularCheckBox; text: "Specular"; checked: true }
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
}
