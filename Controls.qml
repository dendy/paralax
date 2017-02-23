
import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2

Item {
	id: self

	property alias softness: softnessSlider.value
	property alias ascend: ascendSlider.value
	property alias samples: samplesSlider.value
	property alias specular: specularCheckBox.checked
	property alias animate: animateLightCheckBox.checked
	property int colorMapSize: colorMapSizeGroup.current.size
	property int lightMapSize: lightMapSizeGroup.current.size
	property int specularMapSize: specularMapSizeGroup.current.size

	property alias iconScale: iconScaleSlider.value

	property bool isClear: iconView.model.get(iconView.currentIndex).clear === true

	property var lightModel

	property string currentIcon: isClear ? '' : iconView.model.get(iconView.currentIndex).name

	function setCustomLightPos(pos) {
		lightView.currentItem.customPos = pos;
	}

	ColumnLayout {
		id: controlsLayout

		anchors.fill: parent

		Row {
			Text { text: 'Softness:' }
			Slider { id: softnessSlider }
		}

		Row {
			Text { text: 'Light ascend:' }
			Slider { id: ascendSlider; minimumValue: 1.1; maximumValue: 10; value: 3 }
		}

		Row {
			Text { text: 'Samples:' }
			Slider { id: samplesSlider; minimumValue: 0.1; maximumValue: 2.0; value: 0.5 }
		}

		CheckBox { id: specularCheckBox; text: "Specular"; checked: true }
		CheckBox { id: animateLightCheckBox; text: "Animate light"; checked: true }

		Item {
			Layout.fillHeight: true
		}

		property real fboTitleWidth: 60

		Row {
			Text { id: colorTitle; text: 'Color:'; width: controlsLayout.fboTitleWidth }
			ExclusiveGroup { id: colorMapSizeGroup }
			Repeater {
				model: 6
				delegate: RadioButton {
					property int size: Math.pow(2, index + 5)
					exclusiveGroup: colorMapSizeGroup
					text: size
					checked: size === 512
				}
			}
		}

		Row {
			Text { id: lightTitle; text: 'Light:'; width: controlsLayout.fboTitleWidth }
			ExclusiveGroup { id: lightMapSizeGroup }
			Repeater {
				model: 6
				delegate: RadioButton {
					property int size: Math.pow(2, index + 5)
					exclusiveGroup: lightMapSizeGroup
					text: size
					checked: size === 256
				}
			}
		}

		Row {
			Text { id: specularTitle; text: 'Specular:'; width: controlsLayout.fboTitleWidth }
			ExclusiveGroup { id: specularMapSizeGroup }
			Repeater {
				model: 6
				delegate: RadioButton {
					property int size: Math.pow(2, index + 5)
					exclusiveGroup: specularMapSizeGroup
					text: size
					checked: size === 512
				}
			}
		}

		Row {
			Text { text: 'Lights:' }

			Button {
				text: 'Add'
				onClicked: {
					var index = global.addLight({color: 'white', size: 0.5, pos: Qt.point(0.5, 0.5)});
					lightView.currentIndex = index;
				}
			}

			Button {
				text: 'Remove'
				onClicked: {
					global.removeLight(lightView.currentIndex);
				}
			}
		}

		ListView {
			id: lightView
			Layout.preferredHeight: 100
			Layout.fillWidth: true
			model: self.lightModel
			spacing: 10
			orientation: ListView.Horizontal

			property ColorDialog colorDialog: ColorDialog {
				showAlphaChannel: true

				property var light: null

				property Binding colorBinding: Binding {
					target: lightView.colorDialog.light
					property: 'color'
					value: lightView.colorDialog.currentColor
				}
			}

			delegate: Item {
				id: delegate

				property point customPos
				property var light: model.light

				Binding {
					target: delegate.light
					property: 'pos'
					when: !animateLightCheckBox.checked
					value: delegate.customPos
				}

				width: 100
				height: 80

				Rectangle {
					anchors.fill: parent
					color: delegate.light.color
					border.color: 'black'
					border.width: delegate.ListView.isCurrentItem ? 5 : 0
				}

				MouseArea {
					anchors.fill: parent
					onPressed: delegate.ListView.view.currentIndex = model.index;
				}

				Button {
					anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 8 }
					text: 'Select'
					onClicked: {
						lightView.colorDialog.light = null;
						lightView.colorDialog.color = delegate.light.color;
						lightView.colorDialog.open();
						lightView.colorDialog.light = delegate.light;
					}
				}
			}
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
				ListElement { name: 'blender' }
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
					source: model.name ? 'icons/' + model.name + ".png" : ''
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
