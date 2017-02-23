
import QtQuick 2.7

Item {
	id: self

	property Component __pointComponent: Component {
		id: point
		Icon {}
	}

	Item {
		id: colorItem
		width: config.colorMapSize.width
		height: config.colorMapSize.height
	}

	property var colorMap: colorMap

	ShaderEffectSource {
		id: colorMap

		anchors.centerIn: parent
		width: Math.min(parent.width, parent.height)
		height: width

		sourceItem: ShaderEffect {
			width: colorItem.width
			height: colorItem.height
			property var src: ShaderEffectSource { sourceItem: colorItem; hideSource: true }
			property var base: colorMap
			property bool clear: controls.isClear
			property point clearPos: Qt.point(paintArea.mouseX/paintArea.width, paintArea.mouseY/paintArea.height)
			fragmentShader: "
				varying vec2 qt_TexCoord0;
				uniform sampler2D src;
				uniform sampler2D base;
				uniform bool clear;
				uniform vec2 clearPos;
				void main() {
					if (clear) {
						mediump float dist = (1.0 - smoothstep(0.0, 0.1, distance(qt_TexCoord0, clearPos))) * 0.2;
						gl_FragColor = texture2D(base, qt_TexCoord0) - vec4(dist);
					} else {
						gl_FragColor = texture2D(base, qt_TexCoord0) + texture2D(src, qt_TexCoord0);
					}
				}
			"
		}
		live: false
		recursive: true
		textureSize: config.colorMapSize

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
					name: global.controls.currentIcon,
					iconScale: global.controls.iconScale
				}));
				colorMap.scheduleUpdate();
			}

			onPressed: paint(mouse);
			onPositionChanged: paint(mouse);

			Component.onCompleted: {
				addb(0.2, 0.3, 'star', 1.5);
				addb(0.6, 0.7, 'gear', 3.0);
				addb(0.3, 0.4, 'star', 2.5);
				addb(0.8, 0.3, 'cloud', 4.0);
				addb(0.9, 0.8, 'leaf', 2.5);
				colorMap.scheduleUpdate();
			}
		}
	}
}
