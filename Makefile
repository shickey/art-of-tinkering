web:
	# VM
	cp ./vm/dist/web/scratch-vm.min.js ./web/lib/scratch-vm.min.js
	cp ./vm/dist/web/scratch-vm.min.js.map ./web/lib/scratch-vm.min.js.map
	# Blocks
	cp ./blocks/blockly_compressed_vertical.js ./web/lib/blockly_vertical.js
	cp ./blocks/msg/messages.js ./web/lib/messages.js
	cp ./blocks/blocks_compressed.js ./web/lib/blocks.js
	cp ./blocks/blocks_compressed_vertical.js ./web/lib/blocks_vertical.js
	cp -r ./blocks/media ./web
	# Render
	cp ./render/dist/web/scratch-render.min.js ./web/lib/scratch-render.min.js
	cp ./render/dist/web/scratch-render.min.js.map ./web/lib/scratch-render.min.js.map
	# Render Adapters
	cp ./svg-renderer/dist/web/scratch-svg-renderer.js ./web/lib/scratch-svg-renderer.js
	cp ./svg-renderer/dist/web/scratch-svg-renderer.js.map ./web/lib/scratch-svg-renderer.js.map
	# Storage
	cp ./storage/dist/web/scratch-storage.min.js ./web/lib/scratch-storage.min.js
	cp ./storage/dist/web/scratch-storage.min.js.map ./web/lib/scratch-storage.min.js.map

.PHONY: web