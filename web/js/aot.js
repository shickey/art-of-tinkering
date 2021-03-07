;(function() {
  
  var Scratch = {};
  
  Scratch.init = function(defaultAssetFolderUrl, backgroundFilename) {
    
    // Instantiate the VM and create an empty project
    var vm = new VirtualMachine();
    Scratch.vm = vm;
    
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
          defaultAssetFolderUrl,
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
    
    var backgroundHash = backgroundFilename.split('.')[0]

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
            "rotationCenterX": 960,
            "rotationCenterY": 540
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
          if (window.scratchOut) {
            window.scratchOut.postMessage(payload);
          }
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
    
    vm.start();
  }
  
  if (typeof webkit !== 'undefined'
      && typeof webkit.messageHandlers !== 'undefined'
      && typeof webkit.messageHandlers.scratchOut !== 'undefined') {
    window.scratchOut = webkit.messageHandlers.scratchOut;
  }
  window.Scratch = Scratch;
  
})();
