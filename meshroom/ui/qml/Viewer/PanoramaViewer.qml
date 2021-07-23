import QtQuick 2.11
import Utils 1.0

import AliceVision 1.0 as AliceVision

/**
 * PanoramaViwer displays a list of Float Images
 * Requires QtAliceVision plugin.
 */

AliceVision.PanoramaViewer {
    id: root

    width: 3000
    height: 1500

    visible: (status === Image.Ready)

    // paintedWidth / paintedHeight / status for compatibility with standard Image
    property int paintedWidth: sourceSize.width
    property int paintedHeight: sourceSize.height
    property var status: {
        if (readyToLoad === Image.Ready) {
            return Image.Ready;
        }
        else {
            return Image.Null;
        }
    }

    property var readyToLoad: Image.Null

    property int subdivisionsPano: 12

    property bool isEditable: true

    property bool isHighlightable: true

    property bool displayGridPano: true

    property int mouseMultiplier: 1

    property var sfmData: null

    onIsHighlightableChanged:{
        for (var i = 0; i < repeater.model; i++) {
            repeater.itemAt(i).item.onChangedHighlightState(isHighlightable);
        }
    }

    property alias containsMouse: mouseAreaPano.containsMouse

    property bool isRotating: false
    property var lastX : 0
    property var lastY: 0

    property double yaw: 0;
    property int pitch: 0;
    property int roll: 0;

    property var activeNode: _reconstruction.activeNodes.get('SfMTransform').node

    // Yaw and Pitch in Degrees from SfMTransform node sliders
    property int yawNode: activeNode.attribute("manualTransform.manualRotation.y").value;
    property int pitchNode: activeNode.attribute("manualTransform.manualRotation.x").value;
    property int rollNode: activeNode.attribute("manualTransform.manualRotation.z").value;

    function updateRotation(){
        if (!isRotating) {
//            for (var i = 0; i < repeater.model; i++) {
//               repeater.itemAt(i).item.surface.setEulerAngles(yawNode, pitchNode, rollNode);
//            }
        }
    }

    function toDegrees(radians){
        return radians * (180/Math.PI)
    }

    function toRadians(degrees){
        return degrees * (Math.PI/180)
    }

    function fmod(a,b) { return Number((a - (Math.floor(a / b) * b)).toPrecision(8)); }

    function limitAngle(angleDegrees){
            var angleRadians = toRadians(angleDegrees)
            var power = Math.trunc(angleRadians / Math.PI);

            console.warn(power)

            angleRadians = fmod(angleRadians, Math.PI) * Math.pow(-1, power);
            // Radians to Degrees
            var limitedAngleDegrees = toDegrees(angleRadians);
            if (power % 2 != 0) limitedAngleDegrees = -180.0 - limitedAngleDegrees;

            return limitedAngleDegrees;
    }

    onYawNodeChanged: {
        //console.warn("[QML] Yaw node changed")
        updateRotation()
    }
    onPitchNodeChanged: {
        updateRotation()
    }
    onRollNodeChanged: {
        updateRotation()
    }

    Item {
        id: containerPanorama
        z: 10
        Rectangle {
            width: 3000
            height: 1500
            color: "transparent"
            MouseArea {
                id: mouseAreaPano
                anchors.fill: parent
                hoverEnabled: true
                enabled: allImagesLoaded
                cursorShape: {
                    if (isEditable)
                        isRotating ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                }
                onPositionChanged: {
                    // Send Mouse Coordinates to Float Images Viewers
                    for (var i = 0; i < repeater.model && isHighlightable; i++) {
                        var highlight = repeater.itemAt(i).item.getMouseCoordinates(mouse.x, mouse.y);
                        repeater.itemAt(i).z = highlight ? 2 : 0
                        if (highlight)
                        {
                            // Disable Highlight for all other images
                            for (let j = 0; j < repeater.model; j++)
                            {
                                if (j === i) continue;
                                repeater.itemAt(j).item.surface.mouseOver = false;
                                repeater.itemAt(i).z = 0;
                            }
                        }
                    }

                    // Rotate Panorama
                    if (isRotating && isEditable) {
                        var xoffset = mouse.x - lastX;
                        var yoffset = mouse.y - lastY;
                        lastX = mouse.x;
                        lastY = mouse.y;


                        //Rotate roll if alt is pressed
//                        if(mouse.modifiers & Qt.AltModifier){
//                            for (var k = 0; k < repeater.model; k++) {
//                               repeater.itemAt(k).item.surface.incrementEulerAngles(0, 0, (xoffset / width) * mouseMultiplier);
//                            }
//                        }
                        //Default rotate
//                        else{
//                            for (var l = 0; l < repeater.model; l++) {
//                               repeater.itemAt(l).item.surface.incrementEulerAngles((xoffset / width) * mouseMultiplier, -(yoffset / height) * mouseMultiplier, 0);
//                            }
//                        }
                        root.yaw += toDegrees((xoffset / width) * mouseMultiplier)
                        console.warn("Root yaw " + root.yaw)
                        if (root.yaw > 180) root.yaw = -180.0 + (root.yaw - 180.0);
                        if (root.yaw < -180) root.yaw = 180.0 - (Math.abs(root.yaw) - 180);
                        _reconstruction.setAttribute(activeNode.attribute("manualTransform.manualRotation.y"), Math.round(root.yaw));


                    }
                }

                onPressed:{
                    isRotating = true;
                    lastX = mouse.x;
                    lastY = mouse.y;
                }

                onReleased: {
                    if (isRotating)
                    {
                        // Update Euler angles
                        var activeNode = _reconstruction.activeNodes.get('SfMTransform').node;

//                        root.pitch = repeater.itemAt(0).item.surface.getPitch();
//                        root.yaw = repeater.itemAt(0).item.surface.getYaw();
//                        root.roll = repeater.itemAt(0).item.surface.getRoll();

//                        console.warn("Set QML yaw to " + root.yaw)

//                        _reconstruction.setAttribute(
//                            activeNode.attribute("manualTransform.manualRotation"),
//                            JSON.stringify([root.pitch, root.yaw, root.roll])
//                        );
                    }

                    isRotating = false;
                    lastX = 0
                    lastY = 0
                }
            }

            // Grid Panorama Viewer
            Canvas {
                id: gridPano
                visible: displayGridPano
                anchors.fill : parent
                property int wgrid: 40
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.lineWidth = 1.0
                    ctx.shadowBlur = 0
                    ctx.strokeStyle = "grey"
                    var nrows = height/wgrid;
                    for(var i=0; i < nrows+1; i++){
                        ctx.moveTo(0, wgrid*i);
                        ctx.lineTo(width, wgrid*i);
                    }

                    var ncols = width/wgrid
                    for(var j=0; j < ncols+1; j++){
                        ctx.moveTo(wgrid*j, 0);
                        ctx.lineTo(wgrid*j, height);
                    }

                    ctx.closePath()
                    ctx.stroke()
                }
            }
        }
    }


    function updateSfmPath() {
        var activeNode = _reconstruction.activeNodes.get('SfMTransform').node;
        root.sfmPath = (activeNode) ? activeNode.attribute("input").value : "";
    }

    property var pathList : []
    property var idList : []
    property int imagesLoaded: 0
    property bool allImagesLoaded: false

    function loadRepeaterImages(index)
    {
        if (index < repeater.model)
            repeater.itemAt(index).loadItem();
        else
            allImagesLoaded = true;
    }


    Item {
        id: panoImages
        width: root.width
        height: root.height

        Component {
            id: imgPano
            Loader {
                id: floatOneLoader
                active: root.readyToLoad
                visible: (floatOneLoader.status === Loader.Ready)
                z:0
                //anchors.centerIn: parent
                property string cSource: Filepath.stringToUrl(root.pathList[index].toString())
                property int cId: root.idList[index]

                property bool imageLoaded: false
                property bool loading: false

                onImageLoadedChanged: {
                    imagesLoaded++;
                    loadRepeaterImages(imagesLoaded);
                }

                function loadItem() {
                    if(!active)
                        return;

                    if (loading) {
                        loadRepeaterImages(index + 1)
                        return;
                    }

                    loading = true;

                    setSource("FloatImage.qml", {
                        'surface.viewerType': AliceVision.Surface.EViewerType.PANORAMA,
                        'viewerTypeString': 'panorama',
                        'surface.subdivisions': Qt.binding(function() { return subdivisionsPano; }),
                        'surface.yaw': Qt.binding(function() { return root.yaw; }),
                        'index' : index,
                        'idView': Qt.binding(function() { return cId; }),
                        'gamma': Qt.binding(function() { return hdrImageToolbar.gammaValue; }),
                        'gain': Qt.binding(function() { return hdrImageToolbar.gainValue; }),
                        'channelModeString': Qt.binding(function() { return hdrImageToolbar.channelModeValue; }),
                        'downscaleLevel' : Qt.binding(function() { return downscale; }),
                        'source':  Qt.binding(function() { return cSource; }),
                        'sfmData': Qt.binding(function() { return sfmData }),
                        'sfmRequired': true,
                        'canBeHovered': true
                    })
                    imageLoaded = Qt.binding(function() { return repeater.itemAt(index).item.status === Image.Ready ? true : false; })
                }

            }
        }
        Repeater {
            id: repeater
            model: 0
            delegate: imgPano

        }
        Connections {
            target: root
            onImagesDataChanged: {
                root.imagesLoaded = 0;

                // Retrieve downscale value from C++
                panoramaViewerToolbar.updateDownscaleValue(root.downscale)

                //We receive the map<ImgPath, idView> from C++
                //Resetting arrays to avoid problem with push
                for (var path in imagesData) {
                    root.pathList.push(path)
                    root.idList.push(imagesData[path])
                }

                //Changing the repeater model (number of elements)
                panoImages.updateRepeater()

                root.readyToLoad = Image.Ready;

                // Load images two by two
                loadRepeaterImages(0);
                loadRepeaterImages(1);
            }
        }

        function updateRepeater() {
            if(repeater.model !== root.pathList.length){
                repeater.model = 0;
            }
            repeater.model = root.pathList.length;
        }
    }



}
