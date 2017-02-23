
import QtQuick 2.7

Item {
	id: self

	property string name: 'star'
	property real iconScale: 1.0

	Image {
		anchors.centerIn: parent
		width: 40
		height: width
		source: self.name ? 'icons/' + self.name + '.png' : ''
		opacity: 0.2
		scale: self.iconScale
	}
}
