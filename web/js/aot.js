;(function() {
  
  var Scratch = {};
  
  Scratch.init = function(defaultAssetFolderUrl, backgroundFilename) {
    
    // Instantiate the VM and create an empty project
    var vm = new VirtualMachine();
    Scratch.vm = vm;
    
    var video = document.getElementById('video');
    var canvas = document.getElementById('stage');
    var renderer = new ScratchRender(canvas, -960, 960, -540, 540);
    Scratch.renderer = renderer;
    vm.attachRenderer(renderer);
    vm.attachV2SVGAdapter(new ScratchSVGRenderer.SVGRenderer());
    vm.attachV2BitmapAdapter(new ScratchSVGRenderer.BitmapAdapter());
    
    var storage = new ScratchStorage();
    var AssetType = storage.AssetType;
    
    storage.addWebStore(
      [AssetType.ImageVector, AssetType.ImageBitmap, AssetType.Sound],
      function(asset) {
        var assetUrlParts = [
          // defaultAssetFolderUrl,
          'assets/',
          asset.assetId,
          '.',
          asset.dataFormat
        ];
        return assetUrlParts.join('');
      }
    );
    
    vm.attachStorage(storage);
    Scratch.storage = storage;
    
    
    // Set up touch/mouse event handling
    Scratch.mouseState = {
      mouseDown: false,
      mouseDownPosition: null,
      mouseTimeoutId: null
    };
      
    var dragThreshold = 3;
    Scratch.dragState = {
      isDragging: false,
      dragId: null,
      dragOffset: null
    };
      
      
    function getEventXY(e) {
      if (e.touches && e.touches[0]) {
          return {x: e.touches[0].clientX, y: e.touches[0].clientY};
      } else if (e.changedTouches && e.changedTouches[0]) {
          return {x: e.changedTouches[0].clientX, y: e.changedTouches[0].clientY};
      }
      return {x: e.clientX, y: e.clientY};
    };
    
    function onMouseDown (e) {
      var rect = canvas.getBoundingClientRect();
      var XY = getEventXY(e);
      var x = XY.x;
      var y = XY.y;
      var mousePosition = [x - rect.left, y - rect.top];
      if (e.button === 0 || (window.TouchEvent && e instanceof TouchEvent)) {
        Scratch.mouseState = {
          mouseDown: true,
          mouseDownPosition: mousePosition,
          mouseDownTimeoutId: setTimeout(
            onStartDrag(mousePosition[0], mousePosition[1]),
            400
            )
        };
      }
      var data = {
        isDown: true,
        x: mousePosition[0],
        y: mousePosition[1],
        canvasWidth: rect.width,
        canvasHeight: rect.height
      };
      vm.postIOData('mouse', data);
      if (e.preventDefault) {
        // Prevent default to prevent touch from dragging page
        e.preventDefault();
        // But we do want any active input to be blurred
        if (document.activeElement && document.activeElement.blur) {
          document.activeElement.blur();
        }
      }
    }
    
    function getScratchCoords (x, y) {
      var rect = canvas.getBoundingClientRect();
      var nativeSize = renderer.getNativeSize();
      return [
        (nativeSize[0] / rect.width) * (x - (rect.width / 2)),
        (nativeSize[1] / rect.height) * (y - (rect.height / 2))
      ];
    }
    
    function cancelMouseDownTimeout () {
      if (Scratch.mouseState.mouseDownTimeoutId !== null) {
        clearTimeout(Scratch.mouseState.mouseDownTimeoutId);
      }
      Scratch.mouseState.mouseDownTimeoutId = null;
    }
    
    function onMouseMove (e) {
      var rect = canvas.getBoundingClientRect();
      var XY = getEventXY(e);
      var x = XY.x;
      var y = XY.y;
      var mousePosition = [x - rect.left, y - rect.top];

      if (Scratch.mouseState.mouseDown && !Scratch.dragState.isDragging) {
        var distanceFromMouseDown = Math.sqrt(
          Math.pow(mousePosition[0] - Scratch.mouseState.mouseDownPosition[0], 2) +
          Math.pow(mousePosition[1] - Scratch.mouseState.mouseDownPosition[1], 2)
          );
        if (distanceFromMouseDown > dragThreshold) {
          cancelMouseDownTimeout();
          var mouseDownPosition = Scratch.mouseState.mouseDownPosition;
          onStartDrag(mouseDownPosition[0], mouseDownPosition[1]);
        }
      }
      if (Scratch.mouseState.mouseDown && Scratch.dragState.isDragging) {
        var spritePosition = getScratchCoords(mousePosition[0], mousePosition[1]);
        vm.postSpriteInfo({
          x: spritePosition[0] + Scratch.dragState.dragOffset[0],
          y: -(spritePosition[1] + Scratch.dragState.dragOffset[1]),
          force: true
        });
      }
      var coordinates = {
        x: mousePosition[0],
        y: mousePosition[1],
        canvasWidth: rect.width,
        canvasHeight: rect.height
      };
      vm.postIOData('mouse', coordinates);
    }
    
    function onMouseUp (e) {
      var rect = canvas.getBoundingClientRect();
      var XY = getEventXY(e);
      var x = XY.x;
      var y = XY.y;
      var mousePosition = [x - rect.left, y - rect.top];
      cancelMouseDownTimeout();
      Scratch.mouseState = {
        mouseDown: false,
        mouseDownPosition: null
      };
      var data = {
        isDown: false,
        x: x - rect.left,
        y: y - rect.top,
        canvasWidth: rect.width,
        canvasHeight: rect.height,
        wasDragged: Scratch.dragState.isDragging
      };
      if (Scratch.dragState.isDragging) {
        onStopDrag(mousePosition[0], mousePosition[1]);
      }
      vm.postIOData('mouse', data);
    }
    
    function onStartDrag(x, y) {
      if (Scratch.dragState.dragId) return;
      var drawableId = renderer.pick(x, y);
      if (drawableId === null) return;
      var targetId = vm.getTargetIdForDrawableId(drawableId);
      if (targetId === null) return;

      var target = vm.runtime.getTargetById(targetId);

      // Do not start drag unless target is draggable
      if (!target.draggable) return;

      // Dragging always brings the target to the front
      target.goToFront();

      // Extract the drawable art
      var drawableData = renderer.extractDrawable(drawableId, x, y);

      vm.startDrag(targetId);
      Scratch.dragState = {
        isDragging: true,
        dragId: targetId,
        dragOffset: drawableData.scratchOffset
      };
    }
    
    function onStopDrag (mouseX, mouseY) {
      var dragId = Scratch.dragState.dragId;
      vm.stopDrag(dragId);
      Scratch.dragState = {
        isDragging: false,
        dragOffset: null,
        dragId: null
      };
    }
    
    canvas.addEventListener('mousedown', onMouseDown);
    canvas.addEventListener('touchstart', onMouseDown);
    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
    document.addEventListener('touchmove', onMouseMove);
    document.addEventListener('touchend', onMouseUp);
    
    // var backgroundHash = backgroundFilename.split('.')[0]
    var backgroundHash = 'b98ec4bcf90c47bbcacd29012118a419';

    var defaultProject = {
      "targets": [
        {
          "isStage": true,
          "name": "Stage",
          "variables": {},
          "lists": {},
          "broadcasts": {},
          "blocks": {},
          "currentCostume": 0,
          "costumes": [
          {
            "assetId": backgroundHash,
            "name": "backdrop1",
            "bitmapResolution": 1,
            "md5ext": backgroundFilename,
            "dataFormat": "png",
            "rotationCenterX": 1920/2,
            "rotationCenterY": 1080/2
          }
          ],
          "sounds": [],
          "volume": 100,
        }
      ],
      "meta": {
        "semver": "3.0.0",
        "vm": "0.1.0",
        "agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36"
      }
    }
    vm.loadProject(defaultProject).then(() => {
      // Instantiate scratch-blocks and attach it to the DOM.
      var toolbox = document.getElementById('aot-toolbox');
      var workspace = Blockly.inject('blocks-container', {
        media: './media/',
        scrollbars: false,
        trashcan: false,
        horizontalLayout: false,
        sounds: false,
        zoom: {
          startScale: 0.75
        },
        colours: {
          workspace: '#334771',
          flyout: '#283856',
          scrollbar: '#24324D',
          scrollbarHover: '#0C111A',
          insertionMarker: '#FFFFFF',
          insertionMarkerOpacity: 0.3,
          fieldShadow: 'rgba(255, 255, 255, 0.3)',
          dragShadowOpacity: 0.6
        },
        toolbox: toolbox
      });

      // // Disable long-press
      Blockly.longStart_ = function() {};

      // Attach blocks to the VM
      workspace.addChangeListener(vm.blockListener);
      var flyoutWorkspace = workspace.getFlyout().getWorkspace();
      flyoutWorkspace.addChangeListener(vm.flyoutBlockListener);

      // Handle VM events
      vm.on('SCRIPT_GLOW_ON', function(data) {
        workspace.glowStack(data.id, true);
      });
      vm.on('SCRIPT_GLOW_OFF', function(data) {
        workspace.glowStack(data.id, false);
      });
      vm.on('BLOCK_GLOW_ON', function(data) {
        workspace.glowBlock(data.id, true);
      });
      vm.on('BLOCK_GLOW_OFF', function(data) {
        workspace.glowBlock(data.id, false);
      });
      vm.on('VISUAL_REPORT', function(data) {
        workspace.reportValue(data.id, data.value);
      });

      vm.on('workspaceUpdate', (data) => {
        workspace.removeChangeListener(vm.blockListener);
        const dom = Blockly.Xml.textToDom(data.xml);
        Blockly.Xml.clearWorkspaceAndLoadFromXml(dom, workspace);
        workspace.addChangeListener(vm.blockListener);
      });

      vm.on('targetsUpdate', () => {
        ['glide', 'move', 'set'].forEach( prefix => {
          const blockX = workspace.getFlyout().getWorkspace().getBlockById(`${prefix}x`);
          if (blockX) {
            const value = Math.round(vm.editingTarget.x).toString();
            blockX.inputList[0].fieldRow[0].setValue(value);
          }
          const blockY = workspace.getFlyout().getWorkspace().getBlockById(`${prefix}y`);
          if (blockY) {
            const value = Math.round(vm.editingTarget.y).toString();
            blockY.inputList[0].fieldRow[0].setValue(value);
          }
        });
      });

    });
    
    // External API
    Scratch.sendToProjector = function(projectId) {
      Scratch.vm.exportSprite(Scratch.vm.editingTarget.id, {iosId: projectId}).then((zipBlob) => {
        var fileReader = new FileReader();
        fileReader.onload = function() {
          var payload = fileReader.result;
          var url = document.getElementById('ip-field').value;
		  fetch(url, {
			method: 'POST',
			body: payload
		  });
          // if (window.scratchOut) {
            // window.scratchOut.postMessage(payload);
          // }
        }
        fileReader.readAsBinaryString(zipBlob);
      })
    }
    
    Scratch.injectBase64Sprite3Data = function(base64Sprite3Data) {
      var binaryData = window.atob(base64Sprite3Data);
      var bytes = new Uint8Array(binaryData.length);
      for (var i = 0; i < binaryData.length; i++) {
          bytes[i] = binaryData.charCodeAt(i);
      }
      Scratch.vm.addSprite(bytes.buffer);
    }

    Scratch.createVMAsset = function(data) {
        const asset = Scratch.storage.createAsset(
            Scratch.storage.AssetType.ImageBitmap,
            Scratch.storage.DataFormat.PNG,
            data,
            null,
            true
        );

        return {
            name: null, // Needs to be set by caller
            dataFormat: Scratch.storage.DataFormat.PNG,
            asset: asset,
            md5: `${asset.assetId}.${Scratch.storage.DataFormat.PNG}`,
            assetId: asset.assetId
        };
    }
    
    vm.start();
  }
  
  if (typeof webkit !== 'undefined'
      && typeof webkit.messageHandlers !== 'undefined'
      && typeof webkit.messageHandlers.scratchOut !== 'undefined') {
    window.scratchOut = webkit.messageHandlers.scratchOut;
  }
  window.Scratch = Scratch;
  
})();

// window.onload = Scratch.init();
window.onload = () => {
    const projectGalleryDiv = document.getElementById('project-gallery');
    const newProjectModal = document.getElementById('new-project-modal');

    const sendButton = document.getElementById('scratch-button');
    const magicWandButton = document.getElementById('magicwand-tool');
    const lassoButton = document.getElementById('lasso-tool');

    // const cameraDropdown = document.getElementById('device-dropdown');

    const canvas = document.getElementById('canvas');
    var hiddenCanvas = document.createElement('canvas');
    hiddenCanvas.width = 1920;
    hiddenCanvas.height = 1080;
    var hiddenCtx = hiddenCanvas.getContext('2d');
    const ctx = canvas.getContext('2d');

    let removalThreshold = 10;
	let dragging = false;
	let dragStartCoords = [0, 0];

    let capturing = true;

    let projectId;

    let selectedTool = 'magic';

    let imageCaptureData;
    let hiddenCaptureData;

    function startCam(id) {
      navigator.mediaDevices.getUserMedia({video: { width: 1920, height: 1080 }})
      .then((stream) => {
              let settings = stream.getVideoTracks()[0].getSettings();
              camWidth = settings.width;
              camHeight = settings.height;
              video.srcObject = stream;
            })
      .catch(err => console.log(err));
    }

    function stopCam() {
        const tracks = video.srcObject.getTracks();
        tracks.forEach(track => {
            track.stop();
        });
        video.srcObject = null;
    }

    function capture() {
        video.pause();
        let camWidth = 1920;
        let camHeight = 1080;
        let widthRatio = canvas.width / camWidth;
        let heightRatio = canvas.height / camHeight;
        hiddenCtx.drawImage(video, 0, 0, 1920, 1080);
        hiddenCaptureData = hiddenCtx.getImageData(0, 0, hiddenCanvas.width, hiddenCanvas.height).data;
        ctx.drawImage(video, (canvas.width - (camWidth * heightRatio)) / 2, 0, camWidth * heightRatio, camHeight * heightRatio);
        imageCaptureData = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
        canvas.style.display = 'inline';
        video.style.display = 'none';
        stopCam();
    }

	function rgbToHSL(rgb) {
        let r = rgb[0] / 255;
        let g = rgb[1] / 255;
        let b = rgb[2] / 255;
        let max = Math.max(r, g, b);
        let min = Math.min(r, g, b);
        let h, s, l = (max + min) / 2;
        if (max == min) {
            h = s = 0;
        } else {
            let d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }
        return [h*360, s, l];
    }

    function removeColor() {
        if (!selectedColor) return;
        let ctxData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        let hiddenCtxData = hiddenCtx.getImageData(0, 0, hiddenCanvas.width, hiddenCanvas.height);
        let px = ctxData.data;
        let hpx = hiddenCtxData.data;
        px.set(imageCaptureData);
        hpx.set(hiddenCaptureData);
        removeHSL(px, rgbToHSL(selectedColor));
        ctx.putImageData(ctxData, 0, 0);
        removeHSL(hpx, rgbToHSL(selectedColor));
        hiddenCtx.putImageData(hiddenCtxData, 0, 0);

    }

    function resetImage() {
        let ctxData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        ctxData.data.set(imageCaptureData);
        ctx.putImageData(ctxData, 0, 0);
        let hCtxData = hiddenCtx.getImageData(0, 0, hiddenCanvas.width, hiddenCanvas.height);
        hCtxData.data.set(hiddenCaptureData);
        hiddenCtx.putImageData(hCtxData, 0, 0);
    }

    function midPoint(p1, p2) {
        return [
            p1[0] + (p2[0] - p1[0]) / 2,
            p1[1] + (p2[1] - p1[1]) / 2
        ];
    }

    function drawPath(path, closed) {
        resetImage();
        lastX = path[0][0];
        lastY = path[0][1];
        if (closed) {
            ctx.globalCompositeOperation = 'destination-in';
            ctx.beginPath();
            ctx.moveTo(path[0][0], path[0][1]);
            hiddenCtx.globalCompositeOperation = 'destination-in';
            hiddenCtx.beginPath();
            hiddenCtx.moveTo(path[0][0]*4, path[0][1]*4);
            for (p in path) {
                let mid = midPoint([lastX, lastY], path[p]);
                ctx.quadraticCurveTo(lastX, lastY, mid[0], mid[1]);
                hiddenCtx.quadraticCurveTo(lastX*4, lastY*4, mid[0]*4, mid[1]*4);
                // ctx.lineTo(path[p][0], path[p][1]);
                lastX = path[p][0];
                lastY = path[p][1];
            }
            ctx.closePath();
            ctx.fill();
            ctx.globalCompositeOperation = 'source-over';
            hiddenCtx.closePath();
            hiddenCtx.fill();
            hiddenCtx.globalCompositeOperation = 'source-over';
        } else {
            ctx.beginPath();
            ctx.lineWidth = 5;
            ctx.strokeStyle = '#f5e042';
            ctx.moveTo(path[0][0], path[0][1]);
            for (p in path) {
                // ctx.lineTo(path[p][0], path[p][1]);
                let mid = midPoint([lastX, lastY], path[p]);
                ctx.quadraticCurveTo(lastX, lastY, mid[0], mid[1]);
                lastX = path[p][0];
                lastY = path[p][1];
            }
            ctx.stroke();
        }
    }

	function removeHSL(px, hsl) {
        for (let i=0; i < px.length; i+=4) {
            if (Math.abs(rgbToHSL([px[i],px[i+1],px[i+2]])[0] - hsl[0]) < removalThreshold) {
                px[i+3] = 0;
            }
        }
	}

    function convertDataURIToBinary(dataURI) {
        const BASE64_MARKER = ';base64,';
        const base64Index = dataURI.indexOf(BASE64_MARKER) + BASE64_MARKER.length;
        const base64 = dataURI.substring(base64Index);
        const raw = window.atob(base64);
        const rawLength = raw.length;
        const array = new Uint8Array(new ArrayBuffer(rawLength));
        for (let i = 0; i < rawLength; i++) {
            array[i] = raw.charCodeAt(i);
        }
        return array;
    }


    // cameraDropdown.onchange = (event) => {
      // if (capturing) startCam(videoDevices[event.target.value]);
    // };

    // navigator.mediaDevices.enumerateDevices({video: true})
    // .then(devices => {
      // cameraDropdown.innerHTML = '';
      // videoDevices = [];
      // let devs = devices.filter(d => d.kind === 'videoinput');
      // console.log(devs);
      // devs.forEach(d => {
          // let index = videoDevices.push(d.deviceId);
          // let opt = document.createElement('option');
          // opt.value = index;
          // opt.innerHTML = 'Camera ' + index;
          // cameraDropdown.appendChild(opt);
        // });
    // });

    canvas.onmousedown = (event) => {
      if (capturing) return;
	  dragging = true;
      curPath = [];
      let rect = canvas.getBoundingClientRect();
	  dragStartCoords = [
		event.clientX - rect.left,
		event.clientY - rect.top
	  ];
      if (event.button !== 0 || !imageCaptureData) return;
      resetImage();
      if (selectedTool === 'magic') {
          let pixel = ((event.offsetY * canvas.width) + event.offsetX) * 4;
          selectedColor = [imageCaptureData[pixel], imageCaptureData[pixel+1], imageCaptureData[pixel+2]];
          removeColor();
      }
    };

    let curPath = [];
    let curX, curY;
    let lastX, lastY;

    canvas.onmouseenter = (event) => {
        if (selectedTool === 'magic')
            document.body.style.cursor = 'url("./assets/mouse-wand.png"), auto';
        else if (selectedTool === 'lasso')
            document.body.style.cursor = 'url("./assets/mouse-lasso.png"), auto';
        else
            document.body.style.cursor = 'auto';
    };

    canvas.onmouseleave = (event) => {
        document.body.style.cursor = 'auto';
    };

	canvas.onmousemove = (event) => {
		if (!dragging) return;
        lastX = curX;
        lastY = curY;
        let rect = canvas.getBoundingClientRect();
        curX = event.clientX - rect.left;
        curY = event.clientY - rect.top;
        if (selectedTool === 'magic') {
            const distance = Math.sqrt(Math.pow(dragStartCoords[0]-curX, 2) + Math.pow(dragStartCoords[1]-curY, 2));
            removalThreshold = Math.round(distance/2);
            if (removalThreshold < 10) removalThreshold = 10;
            removeColor();
        } else if (selectedTool === 'lasso') {
            if ((lastX !== curX) || (lastY !== curY))
                curPath.push([curX, curY]);
            drawPath(curPath, false);
        }
	};

    canvas.onmouseup = (event) => {
        dragging = false;
        if (selectedTool === 'lasso') {
            drawPath(curPath, true);
        }
    };

    function disableCapturing() {
        capturing = false;
        sendButton.classList.remove('disabled');
        lassoButton.classList.remove('disabled');
        magicWandButton.classList.remove('disabled');
    }

    function enableCapturing() {
        capturing = true;
        sendButton.classList.add('disabled');
        lassoButton.classList.add('disabled');
        magicWandButton.classList.add('disabled');
    }

    document.getElementById('new-project-button').onclick = (event) => {
        projectGalleryDiv.style.display = 'none';
        newProjectModal.style.display = 'block';
        startCam();
    };

    document.getElementById('capture-button').onclick = (event) => {
        if (imageCaptureData) {
            imageCaptureData = null;
            enableCapturing();
            event.target.innerHTML = 'Capture';
            canvas.style.display = 'none';
            video.style.display = 'inline';
            startCam();
        } else {
            disableCapturing();
            capture();
        }
    }

    sendButton.onclick = (event) => {
        if (capturing) return;
        if (!imageCaptureData) return;
        projectGalleryDiv.style.display = 'none';
        newProjectModal.style.display = 'none';
        projectId = (Math.floor(Math.random() * (1000000 - 100000)) + 100000).toString();
        Scratch.init();
        const dataURL = hiddenCanvas.toDataURL('image/png');
        // const dataURL = canvas.toDataURL('image/png');
        const binary = convertDataURIToBinary(dataURL);
        const costume = Scratch.createVMAsset(binary);
        costume.name = 'test';
        const newSprite = {
          name: 'test',
          isStage: false,
          x: 0, // x/y will be randomized below
          y: 0,
          visible: true,
          size: 100,
          rotationStyle: 'all around',
          direction: 90,
          draggable: true,
          currentCostume: 0,
          blocks: {},
          variables: {},
          costumes: [costume],
          sounds: [] // TODO are all of these necessary?
        };
        setTimeout(() => {
            Scratch.vm.addSprite(JSON.stringify(newSprite));
            document.getElementById('app-controls').style.display = 'block';
			document.getElementById('presentation-controls').style.display = 'block';
        }, 500);

    };

    magicWandButton.onclick = (event) => {
        if (capturing) return;
        resetImage();
        selectedTool = 'magic';
        magicWandButton.disabled = true;
        lassoButton.disabled = false;
    };

    lassoButton.onclick = (event) => {
        if (capturing) return;
        resetImage();
        selectedTool = 'lasso';
        magicWandButton.disabled = false;
        lassoButton.disabled = true;
    };

	document.getElementById('upload-button').onclick = (event) => {
		Scratch.sendToProjector(projectId);
	};

    document.getElementById('gf-button').onclick = (event) => {
        Scratch.vm.greenFlag();
    };

    document.getElementById('stop-button').onclick = (event) => {
        Scratch.vm.stopAll();
    };

    // document.getElementById('back-button').onclick = (event) => {
        // Scratch.vm.stopAll();
        // document.getElementById('app-controls').style.display = 'none';
        // document.getElementById('presentation-controls').style.display = 'none';
        // document.getElementById('presentation-controls').style.display = 'none';
        // document.getElementById('blocks-container').style.display = 'none';
        // projectGalleryDiv.style.display = "block";
    // };

    startCam();
};
