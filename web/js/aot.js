;(function() {
  
  var Scratch = {};
  
  Scratch.init = function(defaultAssetFolderUrl, localAssetFolderUrl, imageHash) {
    
    // Instantiate the VM and create an empty project
    var vm = new VirtualMachine();
    Scratch.vm = vm;
    
    var canvas = document.getElementById('stage');
    var renderer = new ScratchRender(canvas, -800, 800, -450, 450);
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
    
    storage.addWebStore(
      [AssetType.ImageVector, AssetType.ImageBitmap, AssetType.Sound],
      function(asset) {
        var assetUrlParts = [
          localAssetFolderUrl,
          asset.assetId,
          '.',
          asset.dataFormat
        ];
        return assetUrlParts.join('');
      }
    );
    
    vm.attachStorage(storage);
    Scratch.storage = storage;

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
            "assetId": "105e0d26858aba223d0e8f759e36db38",
            "name": "backdrop1",
            "bitmapResolution": 1,
            "md5ext": "105e0d26858aba223d0e8f759e36db38.png",
            "dataFormat": "png",
            "rotationCenterX": 240,
            "rotationCenterY": 180
          }
          ],
          "sounds": [],
          "volume": 100,
        },
        {
          isStage: false,
          name: 'myAsset',
          variables: {},
          lists: {},
          broadcasts: {},
          blocks: {},
          currentCostume: 0,
          costumes: [
            {
              assetId: imageHash,
              name: 'cat',
              bitmapResolution: 1,
              md5ext: imageHash + '.png',
              dataFormat: 'png',
              rotationCenterX: 48,
              rotationCenterY: 50
            }
          ],
          sounds: [],
          volume: 100,
          visible: true,
          x: 0,
          y: 0,
          size: 100,
          direction: 90,
          draggable: false,
          rotationStyle: 'all around'
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

    });
    
    vm.start();
  }
  
  window.Scratch = Scratch;
  
})();
