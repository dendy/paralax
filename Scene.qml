
import QtQuick 2.7

QtObject {
	id: self

	property bool animate: false

	property Light redLight: Light {
		color: '#ff80f0'
		size: 0.9

		property real angle: 0
		RotationAnimation on angle {
			from: 0; to: 360
			duration: 5000
			loops: Animation.Infinite
			running: self.animate
		}
		property real radangle: angle * Math.PI / 180.0

		pos: Qt.point(0.5 + Math.sin(radangle) * 0.3, 0.5 + Math.cos(radangle) * 0.3)
	}

	property Light greenLight: Light {
		color: 'white'
		pos: Qt.point(0.5, 0.9)
		size: 0.4

		SequentialAnimation on color {
			ColorAnimation { duration: 5000; to: '#20ff20'; easing.type: Easing.InOutCubic }
			ColorAnimation { duration: 2000; to: '#40cc40'; easing.type: Easing.InOutExpo }
			running: self.animate
			loops: Animation.Infinite
		}
	}

	property Light blueLight: Light {
		color: '#404000ff'
		pos: Qt.point(0.9, by)
		size: 0.6

		property real by
		SequentialAnimation on by {
			NumberAnimation { from: 0; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
			NumberAnimation { from: 1; to: 0; duration: 2000; easing.type: Easing.OutBounce }
			loops: Animation.Infinite
			running: self.animate
		}
	}

	property var lightModel

	Component.onCompleted: {
		lightModel.append({light: self.redLight});
		lightModel.append({light: self.greenLight});
		lightModel.append({light: self.blueLight});
	}

	property Component lightComponent: Component { Light {} }

	function addLight(args) {
		var l = self.lightComponent.createObject(null, args);
		var index = self.lightModel.count;
		self.lightModel.append({light: l});
		return index;
	}

	function removeLight(index) {
		self.lightModel.remove(index);
	}
}
