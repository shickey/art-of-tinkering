web:
	# VM
	cp ./lib/vm/dist/web/scratch-vm.min.js ./web/lib/scratch-vm.min.js
	cp ./lib/vm/dist/web/scratch-vm.min.js.map ./web/lib/scratch-vm.min.js.map
	# Blocks
	cp ./lib/blocks/blockly_compressed_vertical.js ./web/lib/blockly_vertical.js
	cp ./lib/blocks/msg/messages.js ./web/lib/messages.js
	cp ./lib/blocks/blocks_compressed.js ./web/lib/blocks.js
	cp ./lib/blocks/blocks_compressed_vertical.js ./web/lib/blocks_vertical.js
	cp -r ./lib/blocks/media ./web
	# Render
	cp ./lib/render/dist/web/scratch-render.min.js ./web/lib/scratch-render.min.js
	cp ./lib/render/dist/web/scratch-render.min.js.map ./web/lib/scratch-render.min.js.map
	# Render Adapters
	cp ./lib/svg-renderer/dist/web/scratch-svg-renderer.js ./web/lib/scratch-svg-renderer.js
	cp ./lib/svg-renderer/dist/web/scratch-svg-renderer.js.map ./web/lib/scratch-svg-renderer.js.map
	# Storage
	cp ./lib/storage/dist/web/scratch-storage.min.js ./web/lib/scratch-storage.min.js
	cp ./lib/storage/dist/web/scratch-storage.min.js.map ./web/lib/scratch-storage.min.js.map

.PHONY: web