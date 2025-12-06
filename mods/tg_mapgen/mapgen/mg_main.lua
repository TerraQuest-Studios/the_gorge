
core.register_on_generated(function(vm, minp, maxp, blockseed)
	core.generate_decorations(vm, minp, maxp)
	core.generate_ores(vm, minp, maxp)
	vm:calc_lighting()
    vm:update_liquids()
end)
