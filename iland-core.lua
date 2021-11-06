--[[ ------------------------------------------------------

	    __    __        ______    __   __    _____    
	   /\ \  /\ \      /\  __ \  /\ "-.\ \  /\  __-.  
	   \ \ \ \ \ \____ \ \  __ \ \ \ \-.  \ \ \ \/\ \ 
	    \ \_\ \ \_____\ \ \_\ \_\ \ \_\\"\_\ \ \____- 
	     \/_/  \/_____/  \/_/\/_/  \/_/ \/_/  \/____/ 

	  Author   RedbeanW
	  Github   https://github.com/LiteLDev-LXL/iLand-Core
	  License  GPLv3 未经许可禁止商业使用
	  
--]] ------------------------------------------------------

Plugin = {
	version = "2.40",
	numver = 240,
	minLXL = {0,5,6},
}

Server = {
	link = "https://cdn.jsdelivr.net/gh/LiteLDev-LXL/Cloud/",
	memInfo = {}
}

JSON = require('dkjson')
ILAPI={};MEM={}

MainCmd = 'land'
DATA_PATH = 'plugins\\iland\\'
local cfg,land_data,land_owners,wrong_landowners

DEV_MODE = false
if File.exists("EnableILandDevMode") then
	DEV_MODE = true
	DATA_PATH = 'plugins\\LXL_Plugins\\iLand\\iland\\'
end

local minY = -64
local maxY = 320

-- something preload
function CubeToEdge(spos,epos)
	local edge={}
	local posB,posA = SortPos(spos,epos)
	for i=1,math.abs(posA.x-posB.x)+1 do
		edge[#edge+1] = { x=posA.x-i+1, y=posA.y-1, z=posA.z }
		edge[#edge+1] = { x=posA.x-i+1, y=posA.y-1, z=posB.z }
		edge[#edge+1] = { x=posA.x-i+1, y=posB.y-1, z=posA.z }
		edge[#edge+1] = { x=posA.x-i+1, y=posB.y-1, z=posB.z }
	end
	for i=1,math.abs(posA.y-posB.y)+1 do
		edge[#edge+1] = { x=posA.x, y=posA.y-i, z=posA.z }
		edge[#edge+1] = { x=posA.x, y=posA.y-i, z=posB.z }
		edge[#edge+1] = { x=posB.x, y=posA.y-i, z=posB.z }
		edge[#edge+1] = { x=posB.x, y=posA.y-i, z=posA.z }
	end
	for i=1,math.abs(posA.z-posB.z)+1 do
		edge[#edge+1] = { x=posA.x, y=posA.y-1, z=posA.z-i+1 }
		edge[#edge+1] = { x=posB.x, y=posA.y-1, z=posA.z-i+1 }
		edge[#edge+1] = { x=posA.x, y=posB.y-1, z=posA.z-i+1 }
		edge[#edge+1] = { x=posB.x, y=posB.y-1, z=posA.z-i+1 }
	end
	return edge
end
function CubeToEdge_2D(spos,epos)
	local edge={}
	local posB,posA = SortPos(spos,epos)
	for i=1,math.abs(posA.x-posB.x)+1 do
		edge[#edge+1] = { x=posA.x-i+1, y=posA.y-1, z=posA.z }
		edge[#edge+1] = { x=posA.x-i+1, y=posA.y-1, z=posB.z }
	end
	for i=1,math.abs(posA.z-posB.z)+1 do
		edge[#edge+1] = { x=posA.x, y=posA.y-1, z=posA.z-i+1 }
		edge[#edge+1] = { x=posB.x, y=posA.y-1, z=posA.z-i+1 }
	end
	return edge
end

-- map builder
function UpdateChunk(landId,mode)

	-- [CODE] Get all chunk for this land.

	local TxTz={} -- ChunkData(position)
	local ThisRange = land_data[landId].range
	local dimid = ThisRange.dimid
	function ChkNil(table,a,b)
		if table[a]==nil then
			table[a] = {}
		end
		if table[a][b]==nil then
			table[a][b] = {}
		end
	end

	local size = cfg.features.chunk_side
	local sX = ThisRange.start_position[1]
	local sZ = ThisRange.start_position[3]
	local count = 0
	while (sX+size*count<=ThisRange.end_position[1]+size) do
		local Cx,Cz = ToChunkPos({x=sX+size*count,z=sZ+size*count})
		ChkNil(TxTz,Cx,Cz)
		local count2 = 0
		while (sZ+size*count2<=ThisRange.end_position[3]+size) do
			local Cx,Cz = ToChunkPos({x=sX+size*count,z=sZ+size*count2})
			ChkNil(TxTz,Cx,Cz)
			count2 = count2 + 1
		end
		count = count +1
	end

	-- [CODE] Add or Del some chunks.

	for Tx,a in pairs(TxTz) do
		for Tz,b in pairs(a) do
			-- Tx Tz
			if mode=='add' then
				ChkNil(ChunkMap[dimid],Tx,Tz)
				if FoundValueInList(ChunkMap[dimid][Tx][Tz],landId) == -1 then
					table.insert(ChunkMap[dimid][Tx][Tz],#ChunkMap[dimid][Tx][Tz]+1,landId)
				end
			end
			if mode=='del' then
				local p = FoundValueInList(ChunkMap[dimid][Tx][Tz],landId)
				if p~=-1 then
					table.remove(ChunkMap[dimid][Tx][Tz],p)
				end
			end
		end
	end

end
function UpdateLandPosMap(landId,mode)
	if mode=='add' then
		local spos = land_data[landId].range.start_position
		local epos = land_data[landId].range.end_position
		VecMap[landId]={}
		VecMap[landId].a={};VecMap[landId].b={}
		VecMap[landId].a = { x=spos[1], y=spos[2], z=spos[3] } --start
		VecMap[landId].b = { x=epos[1], y=epos[2], z=epos[3] } --end
	end
	if mode=='del' then
		VecMap[landId]=nil
	end
end
function UpdateLandEdgeMap(landId,mode)
	if mode=='del' then
		EdgeMap[landId]=nil
		return
	end
	if mode=='add' then
		EdgeMap[landId]={}
		local spos = ArrayToPos(land_data[landId].range.start_position)
		local epos = ArrayToPos(land_data[landId].range.end_position)
		EdgeMap[landId].D2D = CubeToEdge_2D(spos,epos)
		EdgeMap[landId].D3D = CubeToEdge(spos,epos)
	end
end
function UpdateLandTrustMap(landId)
	LandTrustedMap[landId]={}
	for n,xuid in pairs(land_data[landId].settings.share) do
		LandTrustedMap[landId][xuid]={}
	end
end
function UpdateLandOwnersMap(landId)
	LandOwnersMap[landId]={}
	LandOwnersMap[landId]=ILAPI.GetOwner(landId)
end
function UpdateLandOperatorsMap()
	LandOperatorsMap = {}
	for n,xuid in pairs(cfg.manager.operator) do
		LandOperatorsMap[xuid]={}
	end
end
function BuildListenerMap()
	ListenerDisabled={}
	for n,lner in pairs(cfg.features.disabled_listener) do
		ListenerDisabled[lner] = { true }
	end
end
function BuildUIBITable()
	CanCtlMap = {}
	CanCtlMap[0] = {} -- UseItem
	CanCtlMap[1] = {} -- onBlockInteracted
	CanCtlMap[2] = {} -- ItemWhiteList
	CanCtlMap[3] = {} -- AttackWhiteList
	CanCtlMap[4] = {} -- EntityTypeList
	CanCtlMap[4].animals = {}
	CanCtlMap[4].mobs = {}
	local useItemTmp = {
		'minecraft:bed','minecraft:chest','minecraft:trapped_chest','minecraft:crafting_table',
		'minecraft:campfire','minecraft:soul_campfire','minecraft:composter','minecraft:undyed_shulker_box',
		'minecraft:shulker_box','minecraft:noteblock','minecraft:jukebox','minecraft:bell',
		'minecraft:daylight_detector_inverted','minecraft:daylight_detector','minecraft:lectern',
		'minecraft:cauldron','minecraft:lever','minecraft:stone_button','minecraft:wooden_button',
		'minecraft:spruce_button','minecraft:birch_button','minecraft:jungle_button','minecraft:acacia_button',
		'minecraft:dark_oak_button','minecraft:crimson_button','minecraft:warped_button',
		'minecraft:polished_blackstone_button','minecraft:respawn_anchor','minecraft:trapdoor',
		'minecraft:spruce_trapdoor','minecraft:birch_trapdoor','minecraft:jungle_trapdoor',
		'minecraft:acacia_trapdoor','minecraft:dark_oak_trapdoor','minecraft:crimson_trapdoor',
		'minecraft:warped_trapdoor','minecraft:fence_gate','minecraft:spruce_fence_gate',
		'minecraft:birch_fence_gate','minecraft:jungle_fence_gate','minecraft:acacia_fence_gate',
		'minecraft:dark_oak_fence_gate','minecraft:crimson_fence_gate','minecraft:warped_fence_gate',
		'minecraft:wooden_door','minecraft:spruce_door','minecraft:birch_door','minecraft:jungle_door',
		'minecraft:acacia_door','minecraft:dark_oak_door','minecraft:crimson_door','minecraft:warped_door',
	}
	local blockInterTmp = {
		'minecraft:cartography_table','minecraft:smithing_table','minecraft:furnace','minecraft:blast_furnace',
		'minecraft:smoker','minecraft:brewing_stand','minecraft:anvil','minecraft:grindstone','minecraft:enchanting_table',
		'minecraft:barrel','minecraft:beacon','minecraft:hopper','minecraft:dropper','minecraft:dispenser',
		'minecraft:loom','minecraft:stonecutter_block'
	}
	local itemWlistTmp = {
		'minecraft:glow_ink_sac','minecraft:end_crystal','minecraft:ender_eye','minecraft:axolotl_bucket',
		'minecraft:powder_snow_bucket','minecraft:pufferfish_bucket','minecraft:tropical_fish_bucket',
		'minecraft:salmon_bucket','minecraft:cod_bucket','minecraft:water_bucket','minecraft:cod_bucket',
		'minecraft:lava_bucket','minecraft:bucket','minecraft:flint_and_steel'
	}
	local attackwlistTmp = {
		'minecraft:ender_crystal','minecraft:armor_stand'
	}
	local animals = {
		'minecraft:axolotl','minecraft:bat','minecraft:cat','minecraft:chicken',
		'minecraft:cod','minecraft:cow','minecraft:donkey','minecraft:fox',
		'minecraft:glow_squid','minecraft:horse','minecraft:mooshroom','minecraft:mule',
		'minecraft:ocelot','minecraft:parrot','minecraft:pig','minecraft:rabbit',
		'minecraft:salmon','minecraft:snow_golem','minecraft:sheep','minecraft:skeleton_horse',
		'minecraft:squid','minecraft:strider','minecraft:tropical_fish','minecraft:turtle',
		'minecraft:villager_v2','minecraft:wandering_trader','minecraft:npc' -- npc not animal? hengaaaaaaaa~
	}
	local mobs = {
		-- type A
		'minecraft:pufferfish','minecraft:bee','minecraft:dolphin','minecraft:goat',
		'minecraft:iron_golem','minecraft:llama','minecraft:llama_spit','minecraft:wolf',
		'minecraft:panda','minecraft:polar_bear','minecraft:enderman','minecraft:piglin',
		'minecraft:spider','minecraft:cave_spider','minecraft:zombie_pigman',
		-- type B
		'minecraft:blaze','minecraft:small_fireball','minecraft:creeper','minecraft:drowned',
		'minecraft:elder_guardian','minecraft:endermite','minecraft:evocation_illager','minecraft:evocation_fang',
		'minecraft:ghast','minecraft:fireball','minecraft:guardian','minecraft:hoglin',
		'minecraft:husk','minecraft:magma_cube','minecraft:phantom','minecraft:pillager',
		'minecraft:ravager','minecraft:shulker','minecraft:shulker_bullet','minecraft:silverfish',
		'minecraft:skeleton','minecraft:skeleton_horse','minecraft:slime','minecraft:vex',
		'minecraft:vindicator','minecraft:witch','minecraft:wither_skeleton','minecraft:zoglin',
		'minecraft:zombie','minecraft:zombie_villager_v2','minecraft:piglin_brute','minecraft:ender_dragon',
		'minecraft:dragon_fireball','minecraft:wither','minecraft:wither_skull','minecraft:wither_skull_dangerous'
	}
	for n,uitem in pairs(useItemTmp) do
		CanCtlMap[0][uitem] = { true }
	end
	for n,bint in pairs(blockInterTmp) do
		CanCtlMap[1][bint] = { true }
	end
	for n,iwl in pairs(itemWlistTmp) do
		CanCtlMap[2][iwl] = { true }
	end
	for n,awt in pairs(attackwlistTmp) do
		CanCtlMap[3][awt] = { true }
	end
	for n,anis in pairs(animals) do
		CanCtlMap[4].animals[anis] = { true }
	end
	for n,mons in pairs(mobs) do
		CanCtlMap[4].mobs[mons] = { true }
	end
end
function BuildAnyMap()
	EdgeMap={}
	VecMap={}
	LandTrustedMap={}
	LandOwnersMap={}
	LandOperatorsMap={}
	ChunkMap={}
	ChunkMap[0] = {} -- 主世界
	ChunkMap[1] = {} -- 地狱
	ChunkMap[2] = {} -- 末地
	for landId,data in pairs(land_data) do
		UpdateLandEdgeMap(landId,'add')
		UpdateLandPosMap(landId,'add')
		UpdateChunk(landId,'add')
		UpdateLandTrustMap(landId)
		UpdateLandOwnersMap(landId)
	end
	UpdateLandOperatorsMap()
	BuildUIBITable()
	BuildListenerMap()
end

-- form -> callback
function F_NULL(...) end
function FORM_BACK_LandOPMgr(player,id)
	if not(id) then return end
	GUI_OPLMgr(player)
end
function FORM_BACK_LandMgr(player,id)
	if not(id) then return end
	if MEM[player.xuid].backpo==1 then
		GUI_FastMgr(player)
		return
	end
	GUI_LMgr(player)
end
function FORM_land_buy(player,id)
	if not(id) then
		SendText(player,_Tr('title.buyland.ordersaved','<a>',cfg.features.selection_tool_name));return
	end

	local xuid = player.xuid
	local NewData = MEM[xuid].newLand
	local player_credits = Money_Get(player)
	if NewData.landprice > player_credits then
		SendText(player,_Tr('title.buyland.moneynotenough').._Tr('title.buyland.ordersaved','<a>',cfg.features.selection_tool_name));return
	else
		Money_Del(player,NewData.landprice)
	end
	SendText(player,_Tr('title.buyland.succeed'))
	ILAPI.CreateLand(xuid,NewData.posA,NewData.posB,NewData.dimid)
	MEM[xuid].newLand = nil
	player:sendModalForm(
		'Complete.',
		_Tr('gui.buyland.succeed'),
		_Tr('gui.general.looklook'),
		_Tr('gui.general.cancel'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_cfg(player,data)
	if data==nil then return end
	
	local landId = MEM[player.xuid].landId
	local settings = land_data[landId].settings
	settings.signtome=data[1]
	settings.signtother=data[2]
	settings.signbuttom=data[3]
	settings.ev_explode=data[4]
	settings.ev_farmland_decay=data[5]
	settings.ev_piston_push=data[6]
	settings.ev_fire_spread=data[7]
	ILAPI.save({0,1,0})

	player:sendModalForm(
		_Tr('gui.general.complete'),
		'Complete.',
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_perm(player,data)
	if data==nil then return end
	
	local perm = land_data[MEM[player.xuid].landId].permissions

	perm.allow_place = data[1]
	perm.allow_destroy = data[2]
	perm.allow_entity_destroy = data[3]
	perm.allow_dropitem = data[4]
	perm.allow_pickupitem = data[5]
	perm.allow_ride_entity = data[6]
	perm.allow_ride_trans = data[7]
	perm.allow_shoot = data[8]
	perm.allow_attack_player = data[9]
	perm.allow_attack_animal = data[10]
	perm.allow_attack_mobs = data[11]

	perm.use_crafting_table = data[12]
	perm.use_furnace = data[13]
	perm.use_blast_furnace = data[14]
	perm.use_smoker = data[15]
	perm.use_brewing_stand = data[16]
	perm.use_cauldron = data[17]
	perm.use_anvil = data[18]
	perm.use_grindstone = data[19]
	perm.use_enchanting_table = data[20]
	perm.use_cartography_table = data[21]
	perm.use_smithing_table = data[22]
	perm.use_loom = data[23]
	perm.use_stonecutter = data[24]
	perm.use_lectern = data[25]
	perm.use_beacon = data[26]
	
	perm.use_barrel = data[27]
	perm.use_hopper = data[28]
	perm.use_dropper = data[29]
	perm.use_dispenser = data[30]
	perm.use_shulker_box = data[31]
	perm.allow_open_chest = data[32]
	
	perm.use_campfire = data[33]
	perm.use_firegen = data[34]
	perm.use_door = data[35]
	perm.use_trapdoor = data[36]
	perm.use_fence_gate = data[37]
	perm.use_bell = data[38]
	perm.use_jukebox = data[39]
	perm.use_noteblock = data[40]
	perm.use_composter = data[41]
	perm.use_bed = data[42]
	perm.use_item_frame = data[43]
	perm.use_daylight_detector = data[44]
	perm.use_lever = data[45]
	perm.use_button = data[46]
	perm.use_pressure_plate = data[47]
	perm.allow_throw_potion = data[48]
	perm.use_respawn_anchor = data[49]
	perm.use_fishing_hook = data[50]
	perm.use_bucket = data[51]

	perm.useitem = data[52]

	ILAPI.save({0,1,0})
	player:sendModalForm(
		_Tr('gui.general.complete'),
		'Complete.',
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_name(player,data)
	if data==nil then return end
	
	local landId=MEM[player.xuid].landId
	land_data[landId].settings.nickname=data[1]
	ILAPI.save({0,1,0})
	player:sendModalForm(
		_Tr('gui.general.complete'),
		'Complete.',
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_describe(player,data)
	if data==nil then return end
	
	local landId=MEM[player.xuid].landId
	land_data[landId].settings.describe=data[1]
	ILAPI.save({0,1,0})
	player:sendModalForm(
		_Tr('gui.general.complete'),
		'Complete.',
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_delete(player,id)
	if not(id) then return end
	local xuid=player.xuid
	local landId=MEM[xuid].landId
	ILAPI.DeleteLand(landId)
	Money_Add(player,MEM[xuid].landvalue)
	player:sendModalForm(
		_Tr('gui.general.complete'),
		'Complete.',
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui(player,data,lid)
	if data==nil then return end
	
	local xuid=player.xuid

	local landId
	if lid==nil or lid=='' then
		landId = land_owners[xuid][data[1]+1]
	else
		landId = lid
	end

	MEM[xuid].landId=landId
	if data[2]==0 then --查看领地信息
		local dpos = land_data[landId].range
		local length = math.abs(dpos.start_position[1] - dpos.end_position[1]) + 1 
		local width = math.abs(dpos.start_position[3] - dpos.end_position[3]) + 1
		local height = math.abs(dpos.start_position[2] - dpos.end_position[2]) + 1
		local vol = length * width * height
		local squ = length * width
		local owner = ILAPI.GetOwner(landId)
		if owner~='?' then owner=data.xuid2name(owner) end
		player:sendModalForm(
			_Tr('gui.landmgr.landinfo.title'),
			_Tr('gui.landmgr.landinfo.content',
				'<a>',owner,
				'<b>',landId,
				'<c>',ILAPI.GetNickname(landId,false),
				'<d>',ILAPI.GetDimension(landId),
				'<e>',ToStrDim(dpos.dimid),
				'<f>',PosToText(ArrayToPos(dpos.start_position)),
				'<g>',PosToText(ArrayToPos(dpos.end_position)),
				'<h>',length,'<i>',width,'<j>',height,
				'<k>',squ,'<l>',vol
			),
			_Tr('gui.general.iknow'),
			_Tr('gui.general.close'),
			FORM_BACK_LandMgr
		)
	end
	if data[2]==1 then --编辑领地选项
		local IsSignDisabled = ''
		if not(cfg.features.landSign) then
			IsSignDisabled=' ('.._Tr('talk.features.closed')..')'
		end
		local Form = mc.newCustomForm()
		local settings=land_data[landId].settings
		Form:setTitle(_Tr('gui.landcfg.title'))
		Form:addLabel(_Tr('gui.landcfg.tip'))
		Form:addLabel(_Tr('gui.landcfg.landsign')..IsSignDisabled)
		Form:addSwitch(_Tr('gui.landcfg.landsign.tome'),settings.signtome)
		Form:addSwitch(_Tr('gui.landcfg.landsign.tother'),settings.signtother)
		Form:addSwitch(_Tr('gui.landcfg.landsign.bottom'),settings.signbuttom)
		Form:addLabel(_Tr('gui.landcfg.inside'))
		Form:addSwitch(_Tr('gui.landcfg.inside.explode'),settings.ev_explode) 
		Form:addSwitch(_Tr('gui.landcfg.inside.farmland_decay'),settings.ev_farmland_decay)
		Form:addSwitch(_Tr('gui.landcfg.inside.piston_push'),settings.ev_piston_push)
		Form:addSwitch(_Tr('gui.landcfg.inside.fire_spread'),settings.ev_fire_spread)
		player:sendForm(Form,FORM_land_gui_cfg)
		return
	end
	if data[2]==2 then --编辑领地权限
		local perm = land_data[landId].permissions
		local Form = mc.newCustomForm()
		Form:setTitle(_Tr('gui.landmgr.landperm.title'))
		Form:addLabel(_Tr('gui.landmgr.landperm.options.title'))
		Form:addLabel(_Tr('gui.landmgr.landperm.basic_options'))
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.place'),perm.allow_place)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.destroy'),perm.allow_destroy)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.entity_destroy'),perm.allow_entity_destroy)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.dropitem'),perm.allow_dropitem)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.pickupitem'),perm.allow_pickupitem)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.ride_entity'),perm.allow_ride_entity)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.ride_trans'),perm.allow_ride_trans)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.shoot'),perm.allow_shoot)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.attack_player'),perm.allow_attack_player)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.attack_animal'),perm.allow_attack_animal)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.attack_mobs'),perm.allow_attack_mobs)
		Form:addLabel(_Tr('gui.landmgr.landperm.funcblock_options'))
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.crafting_table'),perm.use_crafting_table)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.furnace'),perm.use_furnace)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.blast_furnace'),perm.use_blast_furnace)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.smoker'),perm.use_smoker)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.brewing_stand'),perm.use_brewing_stand)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.cauldron'),perm.use_cauldron)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.anvil'),perm.use_anvil)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.grindstone'),perm.use_grindstone)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.enchanting_table'),perm.use_enchanting_table)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.cartography_table'),perm.use_cartography_table)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.smithing_table'),perm.use_smithing_table)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.loom'),perm.use_loom)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.stonecutter'),perm.use_stonecutter)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.lectern'),perm.use_lectern)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.beacon'),perm.use_beacon)
		Form:addLabel(_Tr('gui.landmgr.landperm.contblock_options'))
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.barrel'),perm.use_barrel)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.hopper'),perm.use_hopper)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.dropper'),perm.use_dropper)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.dispenser'),perm.use_dispenser)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.shulker_box'),perm.use_shulker_box)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.chest'),perm.allow_open_chest)
		Form:addLabel(_Tr('gui.landmgr.landperm.other_options'))
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.campfire'),perm.use_campfire)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.firegen'),perm.use_firegen)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.door'),perm.use_door)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.trapdoor'),perm.use_trapdoor)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.fence_gate'),perm.use_fence_gate)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.bell'),perm.use_bell)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.jukebox'),perm.use_jukebox)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.noteblock'),perm.use_noteblock)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.composter'),perm.use_composter)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.bed'),perm.use_bed)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.item_frame'),perm.use_item_frame)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.daylight_detector'),perm.use_daylight_detector)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.lever'),perm.use_lever)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.button'),perm.use_button)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.pressure_plate'),perm.use_pressure_plate)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.throw_potion'),perm.allow_throw_potion)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.respawn_anchor'),perm.use_respawn_anchor)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.fishing'),perm.use_fishing_hook)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.bucket'),perm.use_bucket)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.useitem'),perm.useitem)
		Form:addLabel(_Tr('gui.landmgr.landperm.editevent'))
		player:sendForm(Form,FORM_land_gui_perm)
	end
	if data[2]==3 then --编辑信任名单
		local Form = mc.newSimpleForm()
		Form:setTitle(_Tr('gui.landtrust.title'))
		Form:setContent(_Tr('gui.landtrust.tip'))
		Form:addButton(_Tr('gui.landtrust.addtrust'))
		Form:addButton(_Tr('gui.landtrust.rmtrust'))
		player:sendForm(Form,function(pl,dta)
			if dta==nil then return end
			local xuid = pl.xuid
			MEM[xuid].edittype = dta
			-- gen idlist
			if dta==1 then -- del
				local ids = {}
				for i,v in pairs(land_data[MEM[xuid].landId].settings.share) do
					ids[#ids+1] = data.xuid2name(v)
				end
				PSR_New(pl,SRCB_land_trust,ids)
				return
			end
			PSR_New(pl,SRCB_land_trust)
		end)
		return
	end
	if data[2]==4 then --领地nickname
		local nickn=ILAPI.GetNickname(landId,false)
		local Form = mc.newCustomForm()
		Form:setTitle(_Tr('gui.landtag.title'))
		Form:addLabel(_Tr('gui.landtag.tip'))
		Form:addInput("",nickn)
		player:sendForm(Form,FORM_land_gui_name)
		return
	end
	if data[2]==5 then --领地describe
		local desc=ILAPI.GetDescribe(landId)
		if desc=='' then desc='['.._Tr('gui.landmgr.unmodified')..']' end
		local Form = mc.newCustomForm()
		Form:setTitle(_Tr('gui.landdescribe.title'))
		Form:addLabel(_Tr('gui.landdescribe.tip'))
		Form:addInput("",desc)
		player:sendForm(Form,FORM_land_gui_describe)
		return
	end
	if data[2]==6 then --领地过户
		player:sendModalForm(
			_Tr('gui.landtransfer.title'),
			_Tr('gui.landtransfer.tip'),
			_Tr('gui.general.yes'),
			_Tr('gui.general.close'),
			function(pl,ids)
				if not(ids) then return end
				PSR_New(pl,SRCB_land_transfer)
			end
		)
		return
	end
	if data[2]==7 then --重新圈地
		player:sendModalForm(
			_Tr('gui.reselectland.title'),
			_Tr('gui.reselectland.tip'),
			_Tr('gui.general.yes'),
			_Tr('gui.general.cancel'),
			function(player,result)
				local xuid = player.xuid
				if result == nil or result == false then
					return
				end
				MEM[xuid].reselectLand = {
					id=landId,
					step=0
				}
				MEM[xuid].keepingTitle = {
					_Tr('title.selectrange.mode'),
					_Tr('title.selectrange.spointa','<a>',cfg.features.selection_tool_name)
				}
			end
		)
	end
	if data[2]==8 then --删除领地
		local dpos = land_data[landId].range
		local height = math.abs(dpos.start_position[2] - dpos.end_position[2]) + 1
		local length = math.abs(dpos.start_position[1] - dpos.end_position[1]) + 1
		local width = math.abs(dpos.start_position[3] - dpos.end_position[3]) + 1
		MEM[xuid].landvalue=math.modf(CalculatePrice(length,width,height,ILAPI.GetDimension(landId))*cfg.land_buy.refund_rate)
		player:sendModalForm(
			_Tr('gui.delland.title'),
			_Tr('gui.delland.content','<a>',MEM[xuid].landvalue,'<b>',cfg.money.credit_name),
			_Tr('gui.general.yes'),
			_Tr('gui.general.cancel'),
			FORM_land_gui_delete
		);return
	end
end
function FORM_land_mgr(player,data)

	if data==nil then return end
	local xuid=player.xuid
	if data[1]~='' then
		cfg.land.player_max_lands = tonumber(data[1])
	end
	if data[2]~='' then
		cfg.land.land_max_square = tonumber(data[2])
	end
	if data[3]~='' then
		cfg.land.land_min_square = tonumber(data[3])
	end
	cfg.land_buy.refund_rate = data[4]/100
	if data[5]==0 then
		cfg.money.protocol='llmoney'
	else
		cfg.money.protocol='scoreboard'
	end
	if data[6]~='' then
		cfg.money.scoreboard_objname=data[6]
	end
	if data[7]~='' then
		cfg.money.credit_name=data[7]
	end
	cfg.money.discount=data[8]
	if data[9]==0 then
		cfg.land_buy.calculation_3D='m-1'
	end
	if data[9]==1 then
		cfg.land_buy.calculation_3D='m-2'
	end
	if data[9]==2 then
		cfg.land_buy.calculation_3D='m-3'
	end
	if data[10]~='' then
		cfg.land_buy.price_3D[1]=tonumber(data[10])
	end
	if data[11]~='' then
		cfg.land_buy.price_3D[2]=tonumber(data[11])
	end
	if data[12]==0 then
		cfg.land_buy.calculation_2D='d-1'
	end
	if data[13]~='' then
		cfg.land_buy.price_2D[1]=tonumber(data[13])
	end
	cfg.features.landSign = data[14]
	cfg.features.particles = data[15]
	cfg.features.force_talk = data[16]
	-- 18~20 (3) BlockLandDims
	cfg.features.nearby_protection.enabled = data[20]
	cfg.features.nearby_protection.blockselectland = data[21]
	cfg.update_check = data[22]
	cfg.features.auto_update = data[23]
	cfg.features.offlinePlayerInList = data[24]
	cfg.features.land_2D = data[25]
	cfg.features.land_3D = data[26]
	if data[27]~='' then
		cfg.features.playersPerPage=tonumber(data[27])
	end
	if data[28]~='' then
		cfg.features.nearby_protection.side=tonumber(data[28])
	end
	if data[29]~='' then
		cfg.features.selection_tool_name=data[29]
	end
	if data[30]~='' then
		cfg.features.sign_frequency=tonumber(data[30])
	end
	if data[31]~='' then
		cfg.features.chunk_side=tonumber(data[31])
	end
	if data[32]~='' then
		cfg.features.player_max_ple=tonumber(data[32])
	end

	-- BlockLandDims
	local bldims = cfg.features.blockLandDims
	if not(data[17]) then
		bldims[#bldims+1]=0
	end
	if not(data[18]) then
		bldims[#bldims+1]=1
	end
	if not(data[19]) then
		bldims[#bldims+1]=2
	end

	ILAPI.save({1,0,0})
	
	-- Do Realtime

	if cfg.features.landSign and CLOCK_LANDSIGN==nil then
		EnableLandsign()
	end
	if not(cfg.features.landSign) and CLOCK_LANDSIGN~=nil then
		clearInterval(CLOCK_LANDSIGN)
		clearInterval(BUTTOM_SIGN)
		CLOCK_LANDSIGN=nil
		BUTTOM_SIGN=nil
	end

	player:sendModalForm(
		_Tr('gui.general.complete'),
		"Complete.",
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandOPMgr
	)

end
function FORM_land_listener(player,data)
	if data==nil then return end

	cfg.features.disabled_listener = {}
	local dbl = cfg.features.disabled_listener
	if not(data[1]) then dbl[#dbl+1] = "onDestroyBlock" end
	if not(data[2]) then dbl[#dbl+1] = "onPlaceBlock" end
	if not(data[3]) then dbl[#dbl+1] = "onUseItemOn" end
	if not(data[4]) then dbl[#dbl+1] = "onAttack" end
	if not(data[5]) then dbl[#dbl+1] = "onExplode" end
	if not(data[6]) then dbl[#dbl+1] = "onBedExplode" end
	if not(data[7]) then dbl[#dbl+1] = "onRespawnAnchorExplode" end
	if not(data[8]) then dbl[#dbl+1] = "onTakeItem" end
	if not(data[9]) then dbl[#dbl+1] = "onDropItem" end
	if not(data[10]) then dbl[#dbl+1] = "onBlockInteracted" end
	if not(data[11]) then dbl[#dbl+1] = "onUseFrameBlock" end
	if not(data[12]) then dbl[#dbl+1] = "onSpawnProjectile" end
	if not(data[13]) then dbl[#dbl+1] = "onFireworkShootWithCrossbow" end
	if not(data[14]) then dbl[#dbl+1] = "onStepOnPressurePlate" end
	if not(data[15]) then dbl[#dbl+1] = "onRide" end
	if not(data[16]) then dbl[#dbl+1] = "onWitherBossDestroy" end
	if not(data[17]) then dbl[#dbl+1] = "onFarmLandDecay" end
	if not(data[18]) then dbl[#dbl+1] = "onPistonPush" end
	if not(data[19]) then dbl[#dbl+1] = "onFireSpread" end
	
	BuildListenerMap()
	ILAPI.save({1,0,0})
	player:sendModalForm(
		_Tr('gui.general.complete'),
		"Complete.",
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandOPMgr
	)

end
function FORM_land_choseDim(player,id)
	if id==true and not(cfg.features.land_3D) then
		SendText(player,_Tr('gui.buyland.unsupport','<a>','3D'))
		return
	end
	if id==false and not(cfg.features.land_2D) then
		SendText(player,_Tr('gui.buyland.unsupport','<a>','2D'))
		return
	end

	local xuid=player.xuid

	MEM[xuid].keepingTitle = {
		_Tr('title.selectrange.mode'),
		_Tr('title.selectrange.spointa','<a>',cfg.features.selection_tool_name)
	}
	SendText(player,_Tr('title.getlicense.succeed'))
	
	MEM[xuid].newLand={
		dimension = '2D',
		posA = {},
		posB = {},
		step = 0
	}
	if id then
		MEM[xuid].newLand.dimension = '3D'
	end
end
function FORM_landtp(player,id,customID)
	if id==nil or id==0 then return end

	local xuid=player.xuid
	local landId
	if customID~=nil then
		landId = customID
	else
		local lands = ILAPI.GetPlayerLands(xuid)
		for n,landId in pairs(ILAPI.GetAllTrustedLand(xuid)) do
			lands[#lands+1]=landId
		end
	
		landId = lands[id]
	end

	local pos = ILAPI.GetPoint(landId)
	local srt = VecMap[landId].a

	if pos.x==srt.x and (pos.y-1)==srt.y and pos.z==srt.z then
		local msg = _Tr('title.landtp.failbysame')
		if ILAPI.GetOwner(landId)==xuid then
			msg = msg.._Tr('title.landtp.plzset')
		end
		SendText(player,msg)
		return
	end

	if not(IsPosSafe(pos)) then
		SendText(player,_Tr('title.landtp.safetp'))
		return
	end
	
	player:teleport(pos.x,pos.y,pos.z,pos.dimid)
	player:sendModalForm(
		_Tr('gui.general.complete'),
		'Complete.',
		_Tr('gui.general.yes'),
		_Tr('gui.general.close'),
		F_NULL
	)
end
function FORM_land_fast(player,id)
	if id==nil then return end
	local xuid=player.xuid
	MEM[xuid].backpo = 1
	FakeData = {}
	FakeData[2] = id
	if id~=9 then
		FORM_land_gui(player,FakeData,MEM[xuid].landId)
	end
end
function FORM_land_gde(player,id)
	if id==nil then return end
	if id==0 then
		Eventing_onPlayerCmd(player,MainCmd..' new')
	end
	if id==1 then
		Eventing_onPlayerCmd(player,MainCmd..' gui')
	end
	if id==2 then
		Eventing_onPlayerCmd(player,MainCmd..' tp')
	end
end
function SRCB_land_trust(player,selected)
	
	local xuid = player.xuid
	local landId = MEM[xuid].landId
	local data = MEM[xuid].edittype
	local status_list = {}

	if data==0 then -- add
		for n,ID in pairs(selected) do
			local targetXuid=data.name2xuid(ID)
			status_list[ID] = {}
			if ILAPI.GetOwner(landId)==targetXuid then
				status_list[ID] = _Tr('gui.landtrust.fail.cantaddown')
				goto CONTINUE_ADDTRUST
			end
			if ILAPI.AddTrust(landId,targetXuid)==false then
				status_list[ID] = _Tr('gui.landtrust.fail.alreadyexists')
			else
				status_list[ID] = _Tr('gui.landtrust.addsuccess')
			end
			:: CONTINUE_ADDTRUST ::
		end
	end
	if data==1 then -- rm
		for n,ID in pairs(selected) do
			local targetXuid=data.name2xuid(ID)
			ILAPI.RemoveTrust(landId,targetXuid)
			status_list[ID] = {}
			status_list[ID] = _Tr('gui.landtrust.rmsuccess')
		end
	end

	local text = "Completed."
	for i,v in pairs(status_list) do
		text = text..'\n'..i..' => '..v
	end
	player:sendModalForm(
		_Tr('gui.general.complete'),
		text,
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function SRCB_land_transfer(player,selected)
	if #selected > 1 then
		SendText(player,_Tr('title.landtransfer.toomanyids'))
		return
	end

	local xuid=player.xuid
	local landId=MEM[xuid].landId
	local targetXuid=data.name2xuid(selected[1])

	if ILAPI.IsLandOwner(landId,targetXuid) then 
		SendText(player,_Tr('title.landtransfer.canttoown'))
		return
	end
	ILAPI.SetOwner(landId,targetXuid)

	player:sendModalForm(
		_Tr('gui.general.complete'),
		_Tr('title.landtransfer.complete','<a>',ILAPI.GetNickname(landId,true),'<b>',selected[1]),
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function BoughtProg_SelectRange(player,vec4,mode)
	local xuid = player.xuid
    local NewData = MEM[xuid].newLand

    if NewData==nil then return end
    if mode==0 then -- point A
        if mode~=NewData.step then
			SendText(player,_Tr('title.selectrange.failbystep'))
			return
        end
		NewData.posA = vec4
		if FoundValueInList(cfg.features.blockLandDims,vec4.dimid)~=-1 then
			SendText(player,_Tr('title.selectrange.failbydim'))
			MEM[xuid].newLand = nil
			return
		end
		NewData.dimid = vec4.dimid
		if NewData.dimension=='3D' then
			NewData.posA.y=vec4.y
		else
			NewData.posA.y=minY
		end
		MEM[xuid].keepingTitle = {
			_Tr('title.selectrange.mode'),
			_Tr('title.selectrange.spointb','<a>',cfg.features.selection_tool_name)
		}
		SendText(
			player,
			_Tr('title.selectrange.seled',
				'<a>','a',
				'<b>',ToStrDim(vec4.dimid),
				'<c>',NewData.posA.x,
				'<d>',NewData.posA.y,
				'<e>',NewData.posA.z
			)
		)
		NewData.step = 1
    end
    if mode==1 then -- point B
        if vec4.dimid~=NewData.dimid then
			SendText(player,_Tr('title.selectrange.failbycdimid'));return
        end
		NewData.posB = vec4
		if NewData.dimension=='3D' then
			NewData.posB.y=vec4.y
		else
			NewData.posB.y=maxY
		end
		MEM[xuid].keepingTitle = {
			_Tr('title.selectrange.mode'),
			_Tr('title.selectrange.bebuy','<a>',cfg.features.selection_tool_name)
		}
        SendText(
			player,
			_Tr('title.selectrange.seled',
				'<a>','b',
				'<b>',ToStrDim(vec4.dimid),
				'<c>',NewData.posB.x,
				'<d>',NewData.posB.y,
				'<e>',NewData.posB.z
			)
		)
		NewData.step = 2

		local edges
		if NewData.dimension=='3D' then
			edges = CubeToEdge(NewData.posA,NewData.posB)
		else
			edges = CubeToEdge_2D(NewData.posA,NewData.posB)
		end
		if #edges>cfg.features.player_max_ple then
			SendText(player,_Tr('title.selectrange.nople'),0)
		else
			MEM[xuid].particles = edges
		end
    end
	if mode==2 then -- buy Land
		BoughtProg_CreateOrder(player)
	end
end
function BoughtProg_CreateOrder(player)
	local xuid=player.xuid
    local NewData = MEM[xuid].newLand

	if NewData==nil or NewData.step~=2 then
		SendText(player,_Tr('title.createorder.failbystep'))
        return
    end

	MEM[xuid].particles = nil 
    local length = math.abs(NewData.posA.x - NewData.posB.x) + 1
    local width = math.abs(NewData.posA.z - NewData.posB.z) + 1
    local height = math.abs(NewData.posA.y - NewData.posB.y) + 1
    local vol = length * width * height
    local squ = length * width

	function KeepTitle_break()
		MEM[xuid].keepingTitle = {
			_Tr('title.selectrange.mode'),
			_Tr('title.selectrange.spointa','<a>',cfg.features.selection_tool_name)
		}
		NewData.step=0
	end

	--- 违规圈地判断
	local isV = ILAPI.IsLandViolation(squ,height,xuid)
	if isV==-1 then
		KeepTitle_break()
		SendText(player,_Tr('title.createorder.toobig'))
		return
	end
	if isV==-2 then
		KeepTitle_break()
		SendText(player,_Tr('title.createorder.toosmall'))
		return
	end
	if isV==-3 then
		KeepTitle_break()
		SendText(player,_Tr('title.createorder.toolow'))
		return
	end
	
	--- 领地冲突
	local chk = ILAPI.IsLandCollision(NewData.posA,NewData.posB,NewData.dimid)
	if not(chk.status) then
		KeepTitle_break()
		SendText(player,_Tr('title.createorder.collision','<a>',chk.id,'<b>',PosToText(chk.pos)))
		return
	end

	--- 购买
	MEM[xuid].keepingTitle = nil
    NewData.landprice = CalculatePrice(length,width,height,NewData.dimension)
	local dis_info = ''
	local dim_info = ''
	if cfg.money.discount<100 then
		dis_info=_Tr('gui.buyland.discount','<a>',tostring(100-cfg.money.discount))
	end
	if NewData.dimension=='3D' then
		dim_info = '§l3D-Land §r'
	else
		dim_info = '§l2D-Land §r'
	end
	player:sendModalForm(
		dim_info.._Tr('gui.buyland.title')..dis_info,
		_Tr('gui.buyland.content',
			'<a>',length,
			'<b>',width,
			'<c>',height,
			'<d>',vol,
			'<e>',NewData.landprice,
			'<f>',cfg.money.credit_name,
			'<g>',Money_Get(player)
		),
		_Tr('gui.general.buy'),
		_Tr('gui.general.close'),
		FORM_land_buy
	)
end
function BoughtProg_GiveUp(player)
    local xuid = player.xuid
	MEM[xuid].newLand = nil
	MEM[xuid].particles = nil
	MEM[xuid].keepingTitle = nil
	SendText(player,_Tr('title.giveup.succeed'))
end
function ReselectLand_Do(player,vec4,mode)
	local xuid = player.xuid
    local ReData = MEM[xuid].reselectLand
	
    if ReData==nil then return end
    if mode==0 then -- select A
        if mode~=ReData.step then
			SendText(player,_Tr('title.selectrange.failbystep'))
			return
        end
		ReData.posA = vec4
		if FoundValueInList(cfg.features.blockLandDims,vec4.dimid)~=-1 then
			SendText(player,_Tr('title.selectrange.failbydim'))
			MEM[xuid].reselectLand = nil
			return
		end
		ReData.dimid = vec4.dimid
		MEM[xuid].keepingTitle = {
			_Tr('title.selectrange.mode'),
			_Tr('title.selectrange.spointb','<a>',cfg.features.selection_tool_name)
		}
		SendText(
			player,
			_Tr('title.selectrange.seled',
				'<a>','a',
				'<b>',ToStrDim(vec4.dimid),
				'<c>',ReData.posA.x,
				'<d>',ReData.posA.y,
				'<e>',ReData.posA.z
			)
		)
		ReData.step = 1
    end
    if mode==1 then -- point B
        if vec4.dimid~=ReData.dimid then
			SendText(player,_Tr('title.selectrange.failbycdimid'));return
        end
		ReData.posB = vec4
		MEM[xuid].keepingTitle = {
			_Tr('title.selectrange.mode'),
			_Tr('title.reselectland.complete','<a>',cfg.features.selection_tool_name)
		}
        SendText(
			player,
			_Tr('title.selectrange.seled',
				'<a>','b',
				'<b>',ToStrDim(vec4.dimid),
				'<c>',ReData.posB.x,
				'<d>',ReData.posB.y,
				'<e>',ReData.posB.z
			)
		)
		ReData.step = 2

		local edges = CubeToEdge(ReData.posA,ReData.posB)
		if #edges>cfg.features.player_max_ple then
			SendText(player,_Tr('title.selectrange.nople'),0)
		else
			MEM[xuid].particles = edges
		end
    end
	if mode==2 then -- do complete && calculation.
		ReselectLand_Complete(player)
	end
end
function ReselectLand_Complete(player)
	local xuid=player.xuid
    local ReData = MEM[xuid].reselectLand

	if ReData==nil or ReData.step~=2 then
		SendText(player,_Tr('title.createorder.failbystep'))
        return
    end

	MEM[xuid].particles = nil
	ReData.posA,ReData.posB = SortPos(ReData.posA,ReData.posB)
    local length = math.abs(ReData.posA.x - ReData.posB.x) + 1
    local width = math.abs(ReData.posA.z - ReData.posB.z) + 1
    local height = math.abs(ReData.posA.y - ReData.posB.y) + 1
    local squ = length * width

	local oposA = VecMap[ReData.id].a
	local oposB = VecMap[ReData.id].b
	local or_length = math.abs(oposA.x - oposB.x) + 1
    local or_width = math.abs(oposA.z - oposB.z) + 1
    local or_height = math.abs(oposA.y - oposB.y) + 1
    local or_squ = or_length * or_width

	function KeepTitle_break()
		MEM[xuid].keepingTitle = {
			_Tr('title.selectrange.mode'),
			_Tr('title.selectrange.spointa','<a>',cfg.features.selection_tool_name)
		}
		ReData.step=0
	end

	-- 违规圈地判断
	local isV = ILAPI.IsLandViolation(squ,height,xuid)
	if isV==-1 then
		KeepTitle_break()
		SendText(player,_Tr('title.createorder.toobig'))
		return
	end
	if isV==-2 then
		KeepTitle_break()
		SendText(player,_Tr('title.createorder.toosmall'))
		return
	end
	if isV==-3 then
		KeepTitle_break()
		SendText(player,_Tr('title.createorder.toolow'))
		return
	end

	-- 领地冲突
	local chk = ILAPI.IsLandCollision(ReData.posA,ReData.posB,ReData.dimid)
	if not(chk.status) then
		KeepTitle_break()
		SendText(player,_Tr('title.createorder.collision','<a>',chk.id,'<b>',PosToText(chk.pos)))
		return
	end

	-- Checkout
	MEM[xuid].keepingTitle = nil
	player:sendModalForm(
		'Chose Dimension',
		_Tr('gui.reselectland.transferDimension'),
		'2D',
		'3D',
		function(player,result)
			if result==nil then
				return
			end
			local dimension
			if result then -- 2D
				dimension = '2D'
			else -- 3D
				dimension = '3D'
			end
			local nr_price = CalculatePrice(length,width,height,dimension)
			local or_price = CalculatePrice(or_length,or_width,or_height,dimension)
			local mode
			local payT
			if nr_price>=or_price then
				mode = _Tr('gui.reselectland.pay')
				payT = 0
			else
				mode = _Tr('gui.reselectland.refund')
				payT = 1
			end
			local needto = math.abs(nr_price-or_price)
			local landId = MEM[xuid].reselectLand.id
			player:sendModalForm(
				'Checkout',
				_Tr('gui.reselectland.content',
					'<a>',ILAPI.GetDimension(landId),
					'<c>',dimension,
					'<b>',or_price,
					'<d>',nr_price,
					'<e>',mode,
					'<f>',needto,
					'<g>',cfg.money.credit_name
				),
				_Tr('gui.general.yes'),
				_Tr('gui.general.cancel'),
				function(player,result)
					if result==nil or not(result) then return end
					if payT==0 then
						if Money_Get(player)<needto then
							SendText(player,_Tr('title.buyland.moneynotenough'))
							return
						end
						Money_Del(player,needto)
					else
						Money_Add(player,needto)
					end
					local pA = ReData.posA
					local pB = ReData.posB
					if dimension == '2D' then
						pA.y = minY
						pB.y = maxY
					end

					UpdateLandEdgeMap(landId,'del') -- rebuild maps.
					UpdateChunk(landId,'del')
					UpdateLandPosMap(landId,'del')

					land_data[landId].range.start_position = {pA.x,pA.y,pA.z}
					land_data[landId].range.end_position = {pB.x,pB.y,pB.z}
					land_data[landId].range.dimid = ReData.dimid
					land_data[landId].settings.tpoint = {
						pA.x,
						pA.y+1,
						pA.z
					}
					MEM[xuid].reselectLand = nil
					
					UpdateLandEdgeMap(landId,'add')
					UpdateChunk(landId,'add')
					UpdateLandPosMap(landId,'add')

					ILAPI.save({0,1,0})
					SendText(player,_Tr('title.reselectland.succeed'))
				end
			)
		end
	)

end
function ReselectLand_GiveUp(player)
    local xuid=player.xuid
	MEM[xuid].reselectLand = nil
	MEM[xuid].particles = nil
	MEM[xuid].keepingTitle = nil
	SendText(player,_Tr('title.reselectland.giveup.succeed'))
end
function GUI_LMgr(player,realMgrLOwn)
	local xuid=player.xuid

	local ownerXuid
	if realMgrLOwn==nil then
		ownerXuid=xuid
	else
		ownerXuid=realMgrLOwn
	end

	local landlst = ILAPI.GetPlayerLands(ownerXuid)
	if #landlst==0 then
		SendText(player,_Tr('title.landmgr.failed'))
		return
	end
	local Form = mc.newSimpleForm()
	Form:setTitle(_Tr('gui.landmgr.title'))
	Form:setContent(_Tr('gui.landmgr.select'))
	for n,landId in pairs(landlst) do
		Form:addButton(ILAPI.GetNickname(landId,true),'textures/ui/worldsIcon')
	end
	MEM[xuid].enableBackButton = 0
	player:sendForm(Form,function(pl,id) -- callback
		if id==nil then return end
		local xuid = pl.xuid
		MEM[xuid].landId = landlst[id+1]
		GUI_FastMgr(pl)
	end)
end
function GUI_OPLMgr(player)

	local Form = mc.newSimpleForm()
	Form:setTitle(_Tr('gui.oplandmgr.landmgr.title'))
	Form:setContent(_Tr('gui.oplandmgr.landmgr.tip'))
	Form:addButton(_Tr('gui.oplandmgr.mgrtype.land'),'textures/ui/icon_book_writable')
	Form:addButton(_Tr('gui.oplandmgr.mgrtype.plugin'),'textures/ui/icon_setting')
	Form:addButton(_Tr('gui.oplandmgr.mgrtype.listener'),'textures/ui/icon_bookshelf')
	Form:addButton(_Tr('gui.general.close'))
	player:sendForm(Form,function(player,id)
		if id==nil then return end
		if id==0 then
			local Form = mc.newSimpleForm()
			Form:setTitle(_Tr('gui.oplandmgr.title'))
			Form:setContent(_Tr('gui.oplandmgr.landmgr.tip'))
			Form:addButton(_Tr('gui.oplandmgr.landmgr.byplayer'),'textures/ui/icon_multiplayer')
			Form:addButton(_Tr('gui.oplandmgr.landmgr.teleport'),'textures/ui/icon_blackfriday')
			Form:addButton(_Tr('gui.oplandmgr.landmgr.byfeet'),'textures/ui/icon_sign')
			Form:addButton(_Tr('gui.general.back'))
			player:sendForm(Form,GUI_OPLMgr_land)
		end
		if id==1 then
			GUI_OPLMgr_plugin(player)
		end
		if id==2 then
			GUI_OPLMgr_listener(player)
		end
	end)

end
function GUI_OPLMgr_land(player,mode)
	if mode==nil then return end

	local xuid = player.xuid
	if mode==0 then -- 按玩家
		PSR_New(player,function(pl,selected) 
			local landlst = {}
			if #selected>1 then
				SendText(pl,_Tr('talk.tomany'))
				return
			end
			local thisXid = data.name2xuid(selected[1])
			GUI_LMgr(pl,thisXid)
		end)
	end
	if mode==1 then -- 传送
		local Form = mc.newSimpleForm()
		Form:setTitle(_Tr('gui.oplandmgr.landmgr.landtp.title'))
		Form:setContent(_Tr('gui.oplandmgr.landmgr.landtp.tip'))
		local landlst = ILAPI.GetAllLands()
		for num,landId in pairs(landlst) do
			local ownerId = ILAPI.GetOwner(landId)
			if ownerId~='?' then ownerId=data.xuid2name(ownerId) end
			Form:addButton(
				_Tr('gui.oplandmgr.landmgr.button',
					'<a>',ILAPI.GetNickname(landId,true),
					'<b>',ownerId
				),
				'textures/ui/worldsIcon'
			)
		end
		MEM[xuid].landlst = landlst
		player:sendForm(Form,function(pl,id) -- callback
			if id==nil then return end
			local xuid = pl.xuid
			local landId = MEM[xuid].landlst[id+1]
			FORM_landtp(pl,1,landId)
		end)
	end
	if mode==2 then -- 脚下
		local landId = ILAPI.PosGetLand(FixBp(player.blockPos))
		if landId==-1 then
			SendText(player,_Tr('gui.oplandmgr.landmgr.byfeet.errbynull'))
			return
		end
		MEM[xuid].landId = landId
		GUI_FastMgr(player,true)
	end
	if mode==3 then -- 返回
		FORM_BACK_LandOPMgr(player,true)
	end

end
function GUI_OPLMgr_plugin(player)

	local xuid  = player.xuid

	-- Set Money Protocol
	local money_protocols = { 'LLMoney', _Tr('talk.scoreboard') }
	local money_default = 0
	if cfg.money.protocol == 'scoreboard' then
		money_default = 1
	end

	-- Land Calculation
	local calculation_3D = { 'm-1', 'm-2', 'm-3' }
	local c3d_default=0
	if cfg.land_buy.calculation_3D == 'm-1' then
		c3d_default=0
	end
	if cfg.land_buy.calculation_3D == 'm-2' then
		c3d_default=1
	end
	if cfg.land_buy.calculation_3D == 'm-3' then
		c3d_default=2
	end
	local calculation_2D = { 'd-1' }
	local aprice = CloneTable(cfg.land_buy.price_3D)
	if aprice[2]==nil then
		aprice[2]=''
	end
	local bprice = CloneTable(cfg.land_buy.price_2D)
	
	-- Blockland Dims
	local enableDims = { true,true,true }
	local bldims = cfg.features.blockLandDims
	if FoundValueInList(bldims,0)~=-1 then
		enableDims[1] = false
	end
	if FoundValueInList(bldims,1)~=-1 then
		enableDims[2] = false
	end
	if FoundValueInList(bldims,2)~=-1 then
		enableDims[3] = false
	end

	-- Build Form
	local Form = mc.newCustomForm()
	Form:setTitle(_Tr('gui.oplandmgr.title'))
	Form:addLabel(_Tr('gui.oplandmgr.tip'))
	Form:addLabel(_Tr('gui.oplandmgr.landcfg'))
	Form:addInput(_Tr('gui.oplandmgr.landcfg.maxland'),tostring(cfg.land.player_max_lands))
	Form:addInput(_Tr('gui.oplandmgr.landcfg.maxsqu'),tostring(cfg.land.land_max_square))
	Form:addInput(_Tr('gui.oplandmgr.landcfg.minsqu'),tostring(cfg.land.land_min_square))
	Form:addSlider(_Tr('gui.oplandmgr.landcfg.refundrate'),0,100,1,cfg.land_buy.refund_rate*100)
	Form:addLabel(_Tr('gui.oplandmgr.economy'))
	Form:addDropdown(_Tr('gui.oplandmgr.economy.protocol'),money_protocols,money_default)
	Form:addInput(_Tr('gui.oplandmgr.economy.sbname'),cfg.money.scoreboard_objname)
	Form:addInput(_Tr('gui.oplandmgr.economy.credit_name'),cfg.money.credit_name)
	Form:addSlider(_Tr('gui.oplandmgr.economy.discount'),0,100,1,cfg.money.discount)
	Form:addDropdown(_Tr('gui.oplandmgr.economy.calculation_3D'),calculation_3D,c3d_default)
	Form:addInput(_Tr('gui.oplandmgr.economy.price')..'[1]',tostring(aprice[1]))
	Form:addInput(_Tr('gui.oplandmgr.economy.price')..'[2]',tostring(aprice[2]))
	Form:addDropdown(_Tr('gui.oplandmgr.economy.calculation_2D'),calculation_2D)
	Form:addInput(_Tr('gui.oplandmgr.economy.price')..'[1]',tostring(bprice[1]))
	Form:addLabel(_Tr('gui.oplandmgr.features'))
	Form:addSwitch(_Tr('gui.oplandmgr.features.landsign'),cfg.features.landSign)
	Form:addSwitch(_Tr('gui.oplandmgr.features.particles'),cfg.features.particles)
	Form:addSwitch(_Tr('gui.oplandmgr.features.forcetalk'),cfg.features.force_talk)
	Form:addSwitch(_Tr('gui.oplandmgr.features.dim0'),enableDims[1])
	Form:addSwitch(_Tr('gui.oplandmgr.features.dim1'),enableDims[2])
	Form:addSwitch(_Tr('gui.oplandmgr.features.dim2'),enableDims[3])
	Form:addSwitch(_Tr('gui.oplandmgr.features.nearbyprotection'),cfg.features.nearby_protection.enabled)
	Form:addSwitch(_Tr('gui.oplandmgr.features.nearbyblockselectland'),cfg.features.nearby_protection.blockselectland)
	Form:addSwitch(_Tr('gui.oplandmgr.features.autochkupd'),cfg.update_check)
	Form:addSwitch(_Tr('gui.oplandmgr.features.autoupdate'),cfg.features.auto_update)
	Form:addSwitch(_Tr('gui.oplandmgr.features.offlinepls'),cfg.features.offlinePlayerInList)
	Form:addSwitch(_Tr('gui.oplandmgr.features.2dland'),cfg.features.land_2D)
	Form:addSwitch(_Tr('gui.oplandmgr.features.3dland'),cfg.features.land_3D)
	Form:addInput(_Tr('gui.oplandmgr.features.playersperpage'),tostring(cfg.features.playersPerPage))
	Form:addInput(_Tr('gui.oplandmgr.features.nearbyside'),tostring(cfg.features.nearby_protection.side))
	Form:addInput(_Tr('gui.oplandmgr.features.seltolname'),cfg.features.selection_tool_name)
	Form:addInput(_Tr('gui.oplandmgr.features.frequency'),tostring(cfg.features.sign_frequency))
	Form:addInput(_Tr('gui.oplandmgr.features.chunksize'),tostring(cfg.features.chunk_side))
	Form:addInput(_Tr('gui.oplandmgr.features.maxple'),tostring(cfg.features.player_max_ple))
		
	player:sendForm(Form,FORM_land_mgr)

end
function GUI_OPLMgr_listener(player)

	local Form = mc.newCustomForm()
	Form:setTitle(_Tr('gui.listenmgr.title'))
	Form:addLabel(_Tr('gui.listenmgr.tip'))
	Form:addSwitch('onDestroyBlock',not(ILAPI.IsDisabled('onDestroyBlock')))
	Form:addSwitch('onPlaceBlock',not(ILAPI.IsDisabled('onPlaceBlock')))
	Form:addSwitch('onUseItemOn',not(ILAPI.IsDisabled('onUseItemOn')))
	Form:addSwitch('onAttack',not(ILAPI.IsDisabled('onAttack')))
	Form:addSwitch('onExplode',not(ILAPI.IsDisabled('onExplode')))
	Form:addSwitch('onBedExplode',not(ILAPI.IsDisabled('onBedExplode')))
	Form:addSwitch('onRespawnAnchorExplode',not(ILAPI.IsDisabled('onRespawnAnchorExplode')))
	Form:addSwitch('onTakeItem',not(ILAPI.IsDisabled('onTakeItem')))
	Form:addSwitch('onDropItem',not(ILAPI.IsDisabled('onDropItem')))
	Form:addSwitch('onBlockInteracted',not(ILAPI.IsDisabled('onBlockInteracted')))
	Form:addSwitch('onUseFrameBlock',not(ILAPI.IsDisabled('onUseFrameBlock')))
	Form:addSwitch('onSpawnProjectile',not(ILAPI.IsDisabled('onSpawnProjectile')))
	Form:addSwitch('onFireworkShootWithCrossbow',not(ILAPI.IsDisabled('onFireworkShootWithCrossbow')))
	Form:addSwitch('onStepOnPressurePlate',not(ILAPI.IsDisabled('onStepOnPressurePlate')))
	Form:addSwitch('onRide',not(ILAPI.IsDisabled('onRide')))
	Form:addSwitch('onWitherBossDestroy',not(ILAPI.IsDisabled('onWitherBossDestroy')))
	Form:addSwitch('onFarmLandDecay',not(ILAPI.IsDisabled('onFarmLandDecay')))
	Form:addSwitch('onPistonPush',not(ILAPI.IsDisabled('onPistonPush')))
	Form:addSwitch('onFireSpread',not(ILAPI.IsDisabled('onFireSpread')))

	player:sendForm(Form,FORM_land_listener)
end
function GUI_FastMgr(player,isOP)
	local xuid=player.xuid
	local thelands=ILAPI.GetPlayerLands(xuid)
	if #thelands==0 and isOP==nil then
		SendText(player,_Tr('title.landmgr.failed'));return
	end

	local landId = MEM[xuid].landId
	if land_data[landId]==nil then
		return
	end

	local Form = mc.newSimpleForm()
	Form:setTitle(_Tr('gui.fastlmgr.title'))
	if isOP==nil then
		Form:setContent(_Tr('gui.fastlmgr.content','<a>',ILAPI.GetNickname(landId,true)))
	else
		Form:setContent(_Tr('gui.fastlmgr.operator'))
	end
	Form:addButton(_Tr('gui.landmgr.options.landinfo'))
	Form:addButton(_Tr('gui.landmgr.options.landcfg'))
	Form:addButton(_Tr('gui.landmgr.options.landperm'))
	Form:addButton(_Tr('gui.landmgr.options.landtrust'))
	Form:addButton(_Tr('gui.landmgr.options.landtag'))
	Form:addButton(_Tr('gui.landmgr.options.landdescribe'))
	Form:addButton(_Tr('gui.landmgr.options.landtransfer'))
	Form:addButton(_Tr('gui.landmgr.options.reselectrange'))
	Form:addButton(_Tr('gui.landmgr.options.delland'))
	Form:addButton(_Tr('gui.general.close'),'textures/ui/icon_import')
	player:sendForm(Form,FORM_land_fast)
end

-- Selector
function PSR_New(player,callback,customlist)
	
	-- get player list
	local pl_list = {}
	local forTol
	if cfg.features.offlinePlayerInList then
		forTol = land_owners
	else
		forTol = MEM
	end
	for xuid,lds in pairs(forTol) do
		pl_list[#pl_list+1] = data.xuid2name(xuid)
	end

	-- set TRS
	local xuid = player.xuid
	MEM[xuid].psr = {
		playerList = {},
		cbfunc = callback,
		nowpage = 1,
		filter = ""
	}

	local perpage = cfg.features.playersPerPage
	if customlist~=nil then
		MEM[xuid].psr.playerList = ToPages(customlist,perpage)
	else
		MEM[xuid].psr.playerList = ToPages(pl_list,perpage)
	end

	-- call
	PSR_Callback(player,'#',true)

end
function PSR_Callback(player,data,isFirstCall)
	if data==nil then
		MEM[player.xuid].psr=nil
		return
	end
	
	-- get data
	local xuid = player.xuid
	local psrdata = MEM[xuid].psr

	local function buildPage(num)
		local tmp = {}
		for i=1,num do
			tmp[i]=_Tr('gui.playerselector.num','<a>',i)
		end
		return tmp
	end

	local perpage = cfg.features.playersPerPage
	local maxpage = #psrdata.playerList
	local rawList = CloneTable(psrdata.playerList[psrdata.nowpage])

	if type(data)=='table' then
		local selected = {}

		-- refresh page
		local npg = data[#data] + 1 -- custom page
		if npg~=psrdata.nowpage and npg<=maxpage then
			psrdata.nowpage = npg
			rawList = CloneTable(psrdata.playerList[npg])
			goto JUMPOUT_PSR_OTHER
		end

		-- create filter
		if data[1]~='' then
			local findTarget = string.lower(data[1])
			local tmpList = {}
			for num,pagelist in pairs(psrdata.playerList) do
				for page,name in pairs(pagelist) do
					if string.find(string.lower(name),findTarget) ~= nil then
						tmpList[#tmpList+1] = name
					end
				end
			end
			local tableList = ToPages(tmpList,perpage)
			if psrdata.nowpage>#tableList then
				psrdata.nowpage = 1
			end
			if tableList[psrdata.nowpage]==nil then
				rawList = {}
				maxpage = 1
			else
				rawList = tableList[psrdata.nowpage]
				maxpage = #tableList
			end
			if psrdata.filter~=data[1] then
				psrdata.filter = data[1]
				goto JUMPOUT_PSR_OTHER
			end
		end
		psrdata.filter = data[1]

		-- gen selects
		for num,key in pairs(data) do
			if num~=1 and num~=#data and key==true then
				selected[#selected+1] = rawList[num-1]
			end
		end
		if next(selected) ~= nil then
			psrdata.cbfunc(player,selected)
			psrdata=nil
			return
		end

		:: JUMPOUT_PSR_OTHER ::
	end

	-- build form
	local Form = mc.newCustomForm()
	Form:setTitle(_Tr('gui.playerselector.title'))
	Form:addLabel(_Tr('gui.playerselector.search.tip'))
	Form:addLabel(_Tr('gui.playerselector.search.tip2'))
	Form:addInput(_Tr('gui.playerselector.search.type'),_Tr('gui.playerselector.search.ph'),psrdata.filter)
	Form:addLabel(
		_Tr('gui.playerselector.pages',
			'<a>',psrdata.nowpage,
			'<b>',maxpage,
			'<c>',#rawList
		)
	)
	for n,plname in pairs(rawList) do
		Form:addSwitch(plname,false)
	end
	Form:addStepSlider(_Tr('gui.playerselector.jumpto'),buildPage(maxpage),psrdata.nowpage-1)
	player:sendForm(Form,PSR_Callback)
end
function ToPages(list,perpage)
	local rtn = {}
	for n,pl in pairs(list) do
		local num = math.ceil(n/perpage)
		if rtn[num]==nil then
			rtn[num] = {}
		end
		rtn[num][#rtn[num]+1] = pl
	end
	return rtn
end
function MakeShortILD(landId)
	return string.sub(landId,0,16) .. '....'
end

-- +-+ +-+ +-+ +-+ +-+
-- |I| |L| |A| |P| |I|
-- +-+ +-+ +-+ +-+ +-+
-- Exported Apis Here!

-- [[ KERNEL ]]
function ILAPI.CreateLand(xuid,startpos,endpos,dimid)
	local landId
	while true do
		landId = GenGUID()
		if land_data[landId]==nil then break end
	end

	local posA,posB = SortPos(startpos,endpos)

	-- LandData Templete
	land_data[landId]={
		settings = {
			share = {},
			tpoint = {
				startpos.x,
				startpos.y+1,
				startpos.z
			},
			nickname = '',
			describe = '',
			signtome = true,
			signtother = true,
			signbuttom = true,
			ev_explode = false,
			ev_farmland_decay = false,
			ev_piston_push = false,
			ev_fire_spread = false
		},
		range = {
			start_position = {
				posA.x,
				posA.y,
				posA.z
			},
			end_position = {
				posB.x,
				posB.y,
				posB.z
			},
			dimid = dimid
		},
		permissions = {}
	}

	local perm = land_data[landId].permissions
	perm.allow_destroy=false
	perm.allow_entity_destroy=false
	perm.allow_place=false
	perm.allow_attack_player=false
	perm.allow_attack_animal=false
	perm.allow_attack_mobs=true
	perm.allow_open_chest=false
	perm.allow_pickupitem=false
	perm.allow_dropitem=true
	perm.use_anvil = false
	perm.use_barrel = false
	perm.use_beacon = false
	perm.use_bed = false
	perm.use_bell = false
	perm.use_blast_furnace = false
	perm.use_brewing_stand = false
	perm.use_campfire = false
	perm.use_firegen = false
	perm.use_cartography_table = false
	perm.use_composter = false
	perm.use_crafting_table = false
	perm.use_daylight_detector = false
	perm.use_dispenser = false
	perm.use_dropper = false
	perm.use_enchanting_table = false
	perm.use_door=false
	perm.use_fence_gate = false
	perm.use_furnace = false
	perm.use_grindstone = false
	perm.use_hopper = false
	perm.use_jukebox = false
	perm.use_loom = false
	perm.use_stonecutter = false
	perm.use_noteblock = false
	perm.use_shulker_box = false
	perm.use_smithing_table = false
	perm.use_smoker = false
	perm.use_trapdoor = false
	perm.use_lectern = false
	perm.use_cauldron = false
	perm.use_lever=false
	perm.use_button=false
	perm.use_respawn_anchor=false
	perm.use_item_frame=false
	perm.use_fishing_hook=false
	perm.use_bucket=false
	perm.use_pressure_plate=false
	perm.allow_throw_potion=false
	perm.allow_ride_entity=false
	perm.allow_ride_trans=false
	perm.allow_shoot=false
	perm.useitem=false

	-- Write data
	if land_owners[xuid]==nil then -- ilapi
		land_owners[xuid]={}
	end

	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	ILAPI.save({0,1,1})
	UpdateChunk(landId,'add')
	UpdateLandPosMap(landId,'add')
	UpdateLandOwnersMap(landId)
	UpdateLandTrustMap(landId)
	UpdateLandEdgeMap(landId,'add')
	return landId
end
function ILAPI.DeleteLand(landId)
	local owner=ILAPI.GetOwner(landId)
	if owner~='?' then
		table.remove(land_owners[owner],FoundValueInList(land_owners[owner],landId))
	end
	UpdateChunk(landId,'del')
	UpdateLandPosMap(landId,'del')
	UpdateLandEdgeMap(landId,'del')
	land_data[landId]=nil
	ILAPI.save({0,1,1})
	return true
end
function ILAPI.PosGetLand(vec4)
	local Cx,Cz = ToChunkPos(vec4)
	local dimid = vec4.dimid
	if ChunkMap[dimid][Cx]~=nil and ChunkMap[dimid][Cx][Cz]~=nil then
		for n,landId in pairs(ChunkMap[dimid][Cx][Cz]) do
			if dimid==land_data[landId].range.dimid and CubeHadPos(vec4,VecMap[landId].a,VecMap[landId].b) then
				return landId
			end
		end
	end
	return -1
end
function ILAPI.GetChunk(vec2,dimid)
	local Cx,Cz = ToChunkPos(vec2)
	if ChunkMap[dimid][Cx]~=nil and ChunkMap[dimid][Cx][Cz]~=nil then
		return CloneTable(ChunkMap[dimid][Cx][Cz])
	end
	return -1
end 
function ILAPI.GetAllLands()
	local lst = {}
	for id,v in pairs(land_data) do
		lst[#lst+1] = id
	end
	return lst
end
function ILAPI.CheckPerm(landId,perm)
	return CloneTable(land_data[landId].permissions[perm])
end
function ILAPI.CheckSetting(landId,cfgname)
	if cfgname=='share' or cfgname=='tpoint' or cfgname=='nickname' or cfgname=='describe' then
		return nil
	end
	return CloneTable(land_data[landId].settings[cfgname])
end
function ILAPI.GetRange(landId)
	return { VecMap[landId].a,VecMap[landId].b,land_data[landId].range.dimid }
end
function ILAPI.GetEdge(landId,dimtype)
	if dimtype=='2D' then
		return CloneTable(EdgeMap[landId].D2D)
	end
	if dimtype=='3D' then
		return CloneTable(EdgeMap[landId].D3D)
	end
end
function ILAPI.GetDimension(landId)
	if land_data[landId].range.start_position[2]==minY and land_data[landId].range.end_position[2]==maxY then
		return '2D'
	else
		return '3D'
	end
end
function ILAPI.GetName(landId)
	return CloneTable(land_data[landId].settings.nickname)
end
function ILAPI.GetDescribe(landId)
	return CloneTable(land_data[landId].settings.describe)
end
function ILAPI.GetOwner(landId)
	for i,v in pairs(land_owners) do
		if FoundValueInList(v,landId)~=-1 then
			return i
		end
	end
	return '?'
end
function ILAPI.GetPoint(landId)
	local i = CloneTable(land_data[landId].settings.tpoint)
	i[4] = land_data[landId].range.dimid
	return ArrayToPos(i)
end
-- [[ INFORMATION => PLAYER ]]
function ILAPI.GetPlayerLands(xuid)
	return CloneTable(land_owners[xuid])
end
function ILAPI.IsPlayerTrusted(landId,xuid)
	if LandTrustedMap[landId][xuid]==nil then
		return false
	else
		return true
	end
end
function ILAPI.IsLandOwner(landId,xuid)
	if LandOwnersMap[landId]==xuid then
		return true
	else
		return false
	end
end
function ILAPI.IsLandOperator(xuid)
	if LandOperatorsMap[xuid]==nil then
		return false
	else
		return true
	end
end
function ILAPI.GetAllTrustedLand(xuid)
	local trusted = {}
	for landId,data in pairs(land_data) do
		if ILAPI.IsPlayerTrusted(landId,xuid) then
			trusted[#trusted+1]=landId
		end
	end
	return trusted
end
-- [[ CONFIGURE ]]
function ILAPI.UpdatePermission(landId,perm,value)
	if land_data[landId]==nil or land_data[landId].permissions[perm]==nil or (value~=true and value~=false) then
		return false
	end
	land_data[landId].permissions[perm]=value
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.UpdateSetting(landId,cfgname,value)
	if land_data[landId]==nil or land_data[landId].settings[cfgname]==nil or value==nil then
		return false
	end
	if cfgname=='share' then
		return false
	end
	land_data[landId].settings[cfgname]=value
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.AddTrust(landId,xuid)
	local shareList = land_data[landId].settings.share
	if ILAPI.IsPlayerTrusted(landId,xuid) then
		return false
	end
	shareList[#shareList+1]=xuid
	UpdateLandTrustMap(landId)
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.RemoveTrust(landId,xuid)
	local shareList = land_data[landId].settings.share
	table.remove(shareList,FoundValueInList(shareList,xuid))
	UpdateLandTrustMap(landId)
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.SetOwner(landId,xuid)
	local ownerXuid = ILAPI.GetOwner(landId)
	table.remove(land_owners[ownerXuid],FoundValueInList(land_owners[ownerXuid],landId))
	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	UpdateLandOwnersMap(landId)
	ILAPI.save({0,0,1})
	return true
end
-- [[ PLUGIN ]]
function ILAPI.GetMoneyProtocol()
	local m = cfg.money.protocol
	if m~="llmoney" and m~="scoreboard" then
		return nil
	end
	return m
end
function ILAPI.GetLanguage()
	return cfg.manager.default_language
end
function ILAPI.GetChunkSide()
	return cfg.features.chunk_side
end
function ILAPI.GetVersion()
	return Plugin.numver
end
-- [[ UNEXPORT FUNCTIONS ]]
function ILAPI.save(mode) -- {config,data,owners}
	if mode[1] == 1 then
		file.writeTo(DATA_PATH..'config.json',JSON.encode(cfg,{indent=true}))
	end
	if mode[2] == 1 then
		file.writeTo(DATA_PATH..'data.json',JSON.encode(land_data))
	end
	if mode[3] == 1 then
		local tmpowners = CloneTable(land_owners)
		for xuid,landIds in pairs(wrong_landowners) do
			tmpowners[xuid] = landIds
		end
		file.writeTo(DATA_PATH..'owners.json',JSON.encode(tmpowners,{indent=true}))
	end
end
function ILAPI.CanControl(mode,name)
	-- mode [0]UseItem [1]onBlockInteracted [2]items [3]attack
	if CanCtlMap[mode][name]==nil then
		return false
	else
		return true
	end
end
function ILAPI.GetNickname(landId,returnIdIfNameEmpty)
	local n = land_data[landId].settings.nickname
	if n=='' then
		n='<'.._Tr('gui.landmgr.unnamed')..'>'
		if returnIdIfNameEmpty then
			n=n..' '..MakeShortILD(landId)
		end
	end
	return n
end
function ILAPI.IsDisabled(listener)
	if ListenerDisabled[listener]~=nil then
		return true
	end
	return false
end
function ILAPI.GetLanguageList(type) -- [0] langs from disk [1] online
	-- [0] return list (0:zh_CN....)
	-- [1] return table (official:....)
	if type == 0 then
		local langs = {}
		for n,file in pairs(file.getFilesList(DATA_PATH..'lang\\')) do
			local tmp = StrSplit(file,'.')
			if tmp[2]=='json' then
				langs[#langs+1] = tmp[1]
			end
		end
		return langs
	end
	if type == 1 then
		local server = GetLink()
		if server ~= false then
			local raw = network.httpGetSync(server..'/languages/repo.json')
			if raw.status==200 then
				return JSON.decode(raw.data)
			else
				ERROR(_Tr('console.getonline.failbycode','<a>',raw.status))
				return false
			end
		else
			ERROR(_Tr('console.getonline.failed'))
			return false
		end
	end
end
function ILAPI.IsLandViolation(square,height,xuid) -- 违规圈地判断
	if square>cfg.land.land_max_square and FoundValueInList(cfg.manager.operator,xuid)==-1 then
		return -1 -- 太大
	end
	if square<cfg.land.land_min_square and FoundValueInList(cfg.manager.operator,xuid)==-1 then
		return -2 -- 太小
	end
	if height<2 then
		return -3 -- 太低
	end
	return true
end
function ILAPI.IsLandCollision(newposA,newposB,newDimid) -- 领地冲突判断
	local edge = CubeToEdge(newposA,newposB)
	for i=1,#edge do
		edge[i].dimid=newDimid
		local tryLand = ILAPI.PosGetLand(edge[i])
		if tryLand ~= -1 then
			return {
				status = false,
				pos = edge[i],
				id = tryLand
			}
		end
	end
	for landId,val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if land_data[landId].range.dimid==newDimid then
			edge = EdgeMap[landId].D3D
			for i=1,#edge do
				if CubeHadPos(edge[i],newposA,newposB)==true then
					return {
						status = false,
						pos = edge[i],
						id = landId
					}
				end
			end
		end
	end
	return { status = true }
end

-- +-+ +-+ +-+   +-+ +-+ +-+
-- |T| |H| |E|   |E| |N| |D|
-- +-+ +-+ +-+   +-+ +-+ +-+

-- feature function
function _Tr(a,...)
	if DEV_MODE and LangPack[a]==nil then
		ERROR('Translation not found: '..a)
	end
	local result = CloneTable(LangPack[a])
	local args = {...}
	local thisWord = false
	for n,word in pairs(args) do
		if thisWord==true then
			result = string.gsub(result,args[n-1],word)
		end
		thisWord = not(thisWord)
	end
	return result
end
function Money_Add(player,value)
	local ptc = cfg.money.protocol
	if ptc=='scoreboard' then
		player:addScore(cfg.money.scoreboard_objname,value);return
	end
	if ptc=='llmoney' then
		money.add(player.xuid,value);return
	end
	ERROR(_Tr('console.error.money.protocol','<a>',ptc))
end
function Money_Del(player,value)
	local ptc = cfg.money.protocol
	if ptc=='scoreboard' then
		player:setScore(cfg.money.scoreboard_objname,player:getScore(cfg.money.scoreboard_objname)-value)
		return
	end
	if ptc=='llmoney' then
		money.reduce(player.xuid,value)
		return
	end
	ERROR(_Tr('console.error.money.protocol','<a>',ptc))
end
function Money_Get(player)
	local ptc = cfg.money.protocol
	if ptc=='scoreboard' then
		return player:getScore(cfg.money.scoreboard_objname)
	end
	if ptc=='llmoney' then
		return money.get(player.xuid)
	end
	ERROR(_Tr('console.error.money.protocol','<a>',ptc))
end
function SendTitle(player,title,subtitle,times)
	local name = player.realName
	if times == nil then
		mc.runcmdEx('titleraw "' .. name .. '" times 20 25 20')
	else
		mc.runcmdEx('titleraw "' .. name .. '" times '..times[1]..' '..times[2]..' '..times[3])
	end
	if subtitle~=nil then
		mc.runcmdEx('titleraw "'..name..'" subtitle {"rawtext": [{"text":"'..subtitle..'"}]}')
	end
	mc.runcmdEx('titleraw "'..name..'" title {"rawtext": [{"text":"'..title..'"}]}')
end
function SendText(player,text,mode)
	-- [mode] 0 = FORCE USE TALK
	if mode==nil and not(cfg.features.force_talk) then 
		player:sendText(text,5)
		return
	end
	if cfg.features.force_talk and mode~=0 then
		player:sendText('§l§b———————————§a LAND §b———————————\n§r'..text)
	end
	if mode==0 then
		player:sendText('§l§b[§a LAND §b] §r'..text)
		return
	end
end
function CubeHadPos(pos,posA,posB) -- 3D
	if (pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x) then
		if (pos.y>=posA.y and pos.y<=posB.y) or (pos.y<=posA.y and pos.y>=posB.y) then
			if (pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z) then
				return true
			end
		end
	end
	return false
end
function CubeHadPos_2D(pos,posA,posB) -- 2D
	if (pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x) then
		if (pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z) then
			return true
		end
	end
	return false
end
function CalculatePrice(length,width,height,dimension)
	local price=0
	if dimension=='3D' then
		local t=cfg.land_buy.price_3D
		if cfg.land_buy.calculation_3D == 'm-1' then
			price=length*width*t[1]+height*t[2]
		end
		if cfg.land_buy.calculation_3D == 'm-2' then
			price=length*width*height*t[1]
		end
		if cfg.land_buy.calculation_3D == 'm-3' then
			price=length*width*t[1]
		end
	end
	if dimension=='2D' then
		local t=cfg.land_buy.price_2D
		if cfg.land_buy.calculation_2D == 'd-1' then
			price=length*width*t[1]
		end
	end
	return math.modf(price*(cfg.money.discount/100))
end
function ToChunkPos(pos)
	local p = cfg.features.chunk_side
	return math.floor(pos.x/p),math.floor(pos.z/p)
end
function SortPos(posA,posB)
	local A = posA
	local B = posB
	if A.x>B.x then A.x,B.x = B.x,A.x end
	if A.y>B.y then A.y,B.y = B.y,A.y end
	if A.z>B.z then A.z,B.z = B.z,A.z end
	return A,B
end
function GenGUID()
	local guid = system.randomGuid()
    return string.format('%s-%s-%s-%s-%s',
        string.sub(guid,1,8),
        string.sub(guid,9,12),
        string.sub(guid,13,16),
        string.sub(guid,17,20),
        string.sub(guid,21,32)
    )
end
function FixBp(pos)
	-- pos.y=pos.y-1
	return pos
end
function ToStrDim(a)
	if a==0 then return _Tr('talk.dim.zero') end
	if a==1 then return _Tr('talk.dim.one') end
	if a==2 then return _Tr('talk.dim.two') end
	return _Tr('talk.dim.other')
end
function TraverseAABB(AAbb,aaBB,did)
	local posA,posB = SortPos(AAbb,aaBB)
	local result = {}
	for ix=posA.x,posB.x do
		for iy=posA.y,posB.y do
			for iz=posA.z,posB.z do
				result[#result+1] = {x=ix,y=iy,z=iz,dimid=did}
			end
		end
	end
	return result
end
function Upgrade(rawInfo)

	local function recoverBackup(dt)
		INFO('AutoUpdate',_Tr('console.autoupdate.recoverbackup'))
		for n,backupfilename in pairs(dt) do
			file.rename(backupfilename..'.bak',backupfilename)
		end
	end

	--  Check Data
	local updata
	if rawInfo.FILE_Version==202 then
		updata = rawInfo.Updates[1]
	else
		ERROR(_Tr('console.getonline.failbyver','<a>',rawInfo.FILE_Version))
		return
	end
	if  rawInfo.DisableClientUpdate then
		ERROR(_Tr('console.update.disabled'))
		return
	end
	
	-- Check Plugin version
	if updata.NumVer<=Plugin.numver then
		ERROR(_Tr('console.autoupdate.alreadylatest','<a>',updata.NumVer..'<='..Plugin.numver))
		return
	end
	INFO('AutoUpdate',_Tr('console.autoupdate.start'))
	
	-- Set Resource
	local RawPath = {}
	local BackupEd = {}
	local server = GetLink()
	local source
	if server ~= false then
		source = server..'/'..updata.NumVer..'/'
	else
		ERROR(_Tr('console.getonline.failed'))
		return false
	end
	
	INFO('AutoUpdate',Plugin.version..' => '..updata.Version)
	RawPath['$plugin_path'] = 'plugins\\'
	RawPath['$data_path'] = DATA_PATH
	
	-- Get it, update.
	for n,thefile in pairs(updata.FileChanged) do
		local raw = StrSplit(thefile,'::')
		local path = RawPath[raw[1]]..raw[2]
		INFO('Network',_Tr('console.autoupdate.download')..raw[2])
		
		if file.exists(path) then -- create backup
			file.rename(path,path..'.bak')
			BackupEd[#BackupEd+1]=path
		end

		local tmp = network.httpGetSync(source..raw[2])
		local tmp2 = network.httpGetSync(source..raw[2]..'.md5.verify')
		if tmp.status~=200 or tmp2.status then -- download check
			ERROR(
				_Tr('console.autoupdate.errorbydown',
					'<a>',raw[2],
					'<b>',tmp.status..','..tmp2.status
				)
			)
			recoverBackup(BackupEd)
			return
		end

		local raw = string.gsub(tmp.data,'\n','\r\n')
		if data.toMD5(raw)~=tmp2.data then -- MD5 check
			ERROR(
				_Tr('console.autoupdate.errorbyverify',
					'<a>',raw[2]
				)
			)
			recoverBackup(BackupEd)
			return
		end

		file.writeTo(path,raw)
	end

	INFO('AutoUpdate',_Tr('console.autoupdate.success'))
end
function ChkNil(val)
	return (val == nil)
end
function ChkNil_X2(val,val2)
	return (val == nil) or (val2 == nil)
end
function EntityGetType(type)
	if type=='minecraft:player' then
		return 0
	end
	if CanCtlMap[4].animals[type]~=nil then
		return 1
	end
	if CanCtlMap[4].mobs[type]~=nil then
		return 2
	end
	return 0
end
function IsPosSafe(pos)
	local posA = {x=pos.x+1,y=pos.y+1,z=pos.z+1,dimid=pos.dimid}
	local posB = {x=pos.x-1,y=pos.y-1,z=pos.z-1,dimid=pos.dimid}
	for n,sta in pairs(TraverseAABB(posA,posB,pos.dimid)) do
		if sta.y~=pos.y-1 and mc.getBlock(sta.x,sta.y,sta.z,sta.dimid).type~='minecraft:air' then
			return false
		end
	end
	return true
end
function FoundValueInList(list, value)
	for i, nowValue in pairs(list) do
        if nowValue == value then
            return i
        end
    end
    return -1
end
function CloneTable(orig) -- [NOTICE] This function from: lua-users.org
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[CloneTable(orig_key)] = CloneTable(orig_value)
        end
        setmetatable(copy, CloneTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
function StrSplit(str,reps) -- [NOTICE] This function from: blog.csdn.net
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function (w)
        table.insert(resultStrList,w)
    end)
    return resultStrList
end
function ArrayToPos(table) -- [x,y,z,d] => {x:x,y:y,z:z,d:d}
	local t={}
	t.x=math.floor(table[1])
	t.y=math.floor(table[2])
	t.z=math.floor(table[3])
	if table[4]~=nil then
		t.dimid=table[4]
	end
		return t
end
function PosToText(vec3)
	return vec3.x..','..vec3.y..','..vec3.z
end
function GetLink()
	local tokenRaw = network.httpGetSync('https://lxl-cloud.amd.rocks/id.json')
	if tokenRaw.status~=200 then
		return false
	end
	local id = JSON.decode(tokenRaw.data).token
	return Server.link..id..'/iLand'
end

-- log system
function INFO(type,content)
	if content==nil then
		print('[ILand] |INFO| '..type)
		return
	end
	print('[ILand] |'..type..'| '..content)
end
function ERROR(content)
	print('[ILand] |ERROR| '..content)
end

-- command helper
function DownloadLanguage(name)
	local lang_n = network.httpGetSync(GetLink()..'/languages/'..name..'.json')
	local lang_v = network.httpGetSync(GetLink()..'/languages/'..name..'.json.md5.verify')
	if lang_n.status~=200 or lang_v.status~=200 then
		ERROR(_Tr('console.languages.install.statfail','<a>',name,'<b>',lang_n.status..','..lang_v.status))
		return false
	end
	local raw = string.gsub(lang_n.data,'\n','\r\n')
	if data.toMD5(raw)~=lang_v.data then
		ERROR(_Tr('console.languages.install.verifyfail','<a>',name))
		return false
	end
	local THISVER = JSON.decode(raw).VERSION
	if THISVER~=Plugin.numver then
		ERROR(_Tr('console.languages.install.versionfail','<a>',name,'<b>',THISVER,'<c>',Plugin.numver))
		return false
	end
	file.writeTo(DATA_PATH..'lang\\'..name..'.json',raw)
	return true
end

-- Minecraft -> Eventing
function Eventing_onJoin(player)
	local xuid = player.xuid
	MEM[xuid] = { inland='null',inlandv2='null' }

	if wrong_landowners[xuid]~=nil then
		land_owners[xuid] = CloneTable(wrong_landowners[xuid])
		wrong_landowners[xuid] = nil
	end
	if land_owners[xuid]==nil then
		land_owners[xuid] = {}
		ILAPI.save({0,0,1})
	end

	if player.gameMode==1 then
		ERROR(_Tr('talk.gametype.creative','<a>',player.realName))
	end
end
function Eventing_onPreJoin(player)
	if player.xuid=='' then -- no xuid
		player:kick(_Tr('talk.prejoin.noxuid'))
	end
end
function Eventing_onLeft(player)

	if ChkNil(player) then
		return
	end

	local xuid = player.xuid
	MEM[xuid]=nil
end
function Eventing_onPlayerCmd(player,cmd)

	local opt = StrSplit(cmd,' ')
	if opt[1] ~= MainCmd then return end

	local xuid = player.xuid
	local pos = FixBp(player.blockPos)

	-- [ ] Main Command
	if opt[1] == MainCmd and opt[2]==nil then
		local landId = ILAPI.PosGetLand(pos)
		if landId~=-1 and ILAPI.GetOwner(landId)==xuid then
			MEM[xuid].landId=landId
			GUI_FastMgr(player)
		else
			local land_count = tostring(#land_owners[xuid])
			local Form = mc.newSimpleForm()
			Form:setTitle(_Tr('gui.fastgde.title'))
			Form:setContent(_Tr('gui.fastgde.content','<a>',land_count))
			Form:addButton(_Tr('gui.fastgde.create'),'textures/ui/icon_iron_pickaxe')
			Form:addButton(_Tr('gui.fastgde.manage'),'textures/ui/confirm')
			Form:addButton(_Tr('gui.fastgde.landtp'),'textures/ui/World')
			Form:addButton(_Tr('gui.general.close'))
			player:sendForm(Form,FORM_land_gde)
		end
		return false
	end

	-- [new] Create newLand
	if opt[2] == 'new' then
		if MEM[xuid].newLand~=nil then
			MEM[xuid].keepingTitle = {
				_Tr('title.selectrange.mode'),
				_Tr('title.selectrange.spointa','<a>',cfg.features.selection_tool_name)
			}
			SendText(player,_Tr('title.getlicense.alreadyexists'))
			return false
		end
		if FoundValueInList(cfg.manager.operator,xuid)==-1 then
			if #land_owners[xuid]>=cfg.land.player_max_lands then
				SendText(player,_Tr('title.getlicense.limit'))
				return false
			end
		end
		player:sendModalForm(
			'DimChosen',
			_Tr('gui.buyland.chosedim'),
			_Tr('gui.buyland.3d'),
			_Tr('gui.buyland.2d'),
			FORM_land_choseDim
		)
		return false
	end

	-- [a|b|buy] Select Range
	if opt[2] == 'a' or opt[2] == 'b' or opt[2] == 'buy' then
		local new = (MEM[xuid].newLand~=nil)
		local res = (MEM[xuid].reselectLand~=nil)
		if not(new) and not(res) then
			SendText(player,_Tr('title.land.nolicense'))
			return false
		end
		if new then
			if (opt[2]=='a' and MEM[xuid].newLand.step~=0) or (opt[2]=='b' and MEM[xuid].newLand.step~=1) or (opt[2]=='buy' and MEM[xuid].newLand.step~=2) then
				SendText(player,_Tr('title.selectrange.failbystep'))
				return false
			end
			BoughtProg_SelectRange(player,pos,MEM[xuid].newLand.step)
		else
			if (opt[2]=='a' and MEM[xuid].reselectLand.step~=0) or (opt[2]=='b' and MEM[xuid].reselectLand.step~=1) then
				SendText(player,_Tr('title.selectrange.failbystep'))
				return false
			end
			if opt[2]~='buy' then
				ReselectLand_Do(player,pos,MEM[xuid].reselectLand.step)
			end
		end
		return false
	end

	-- [giveup] Give up incp land
	if opt[2] == 'giveup' then
		if MEM[xuid].newLand~=nil then
			BoughtProg_GiveUp(player)
		end
		if MEM[xuid].reselectLand~=nil then
			ReselectLand_GiveUp(player)
		end
		return false
	end

	-- [gui] LandMgr GUI
	if opt[2] == 'gui' then
		MEM[xuid].backpo = 0
		GUI_LMgr(player)
		return false
	end

	-- [tp] LandTp GUI
	if opt[2] == 'tp' and cfg.features.landtp then
		if opt[3]==nil then
			local tplands = {}
			for i,landId in pairs(ILAPI.GetPlayerLands(xuid)) do
				local name = ILAPI.GetNickname(landId)
				local xpos = ILAPI.GetPoint(landId)
				tplands[#tplands+1]=ToStrDim(xpos.dimid)..' ('..PosToText(xpos)..') '..name
			end
			for i,landId in pairs(ILAPI.GetAllTrustedLand(xuid)) do
				local name = ILAPI.GetNickname(landId)
				local xpos = ILAPI.GetPoint(landId)
				tplands[#tplands+1]='§l'.._Tr('gui.landtp.trusted')..'§r '..ToStrDim(xpos.dimid)..'('..PosToText(xpos)..') '..name
			end
			local Form = mc.newSimpleForm()
			Form:setTitle(_Tr('gui.landtp.title'))
			Form:setContent(_Tr('gui.landtp.tip'))
			Form:addButton(_Tr('gui.general.close'))
			for i,land in pairs(tplands) do
				Form:addButton(land,'textures/ui/world_glyph_color')
			end
			player:sendForm(Form,FORM_landtp)
			return false
		end
		if opt[3]=='set' then
			local landId=ILAPI.PosGetLand(pos)
			if landId==-1 then
				SendText(player,_Tr('title.landtp.fail.noland'))
				return false
			end
			if ILAPI.GetOwner(landId)~=xuid then
				SendText(player,_Tr('title.landtp.fail.notowner'))
				return false
			end
			if not(IsPosSafe(pos)) then
				SendText(player,_Tr('title.landtp.safeset'))
				return false
			end
			local landname = ILAPI.GetNickname(landId,true)
			land_data[landId].settings.tpoint = {
				pos.x,
				pos.y+1,
				pos.z
			}
			ILAPI.save({0,1,0})
			player:sendModalForm(
				_Tr('gui.general.complete'),
				_Tr('gui.landtp.point','<a>',PosToText({x=pos.x,y=pos.y+1,z=pos.z}),'<b>',landname),
				_Tr('gui.general.iknow'),
				_Tr('gui.general.close'),
				F_NULL
			)
			return false
		end
		if opt[3]=='rm' then
			local landId=ILAPI.PosGetLand(pos)
			if landId==-1 then
				SendText(player,_Tr('title.landtp.fail.noland'))
				return false
			end
			if ILAPI.GetOwner(landId)~=xuid then
				SendText(player,_Tr('title.landtp.fail.notowner'))
				return false
			end
			local def = VecMap[landId].a
			land_data[landId].settings.tpoint = {
				def.x,
				def.y+1,
				def.z
			}
			SendText(player,_Tr('title.landtp.removed'))
			return false
		end
	end

	-- [mgr] OP-LandMgr GUI
	if opt[2] == 'mgr' then
		if opt[3] == nil then -- no child-command.
			if not(ILAPI.IsLandOperator(xuid)) then
				SendText(player,_Tr('command.land_mgr.noperm','<a>',player.realName),0)
				return false
			end
			GUI_OPLMgr(player)
		end
		if opt[3] == 'selectool' then -- set land select_tool.
			if FoundValueInList(cfg.manager.operator,xuid)==-1 then
				SendText(player,_Tr('command.land_mgr.noperm','<a>',player.realName),0)
				return false
			end
			SendText(player,_Tr('title.oplandmgr.setselectool'))
			MEM[xuid].selectool=0
		end
		return false
	end

	-- [X] Unknown key
	SendText(player,_Tr('command.error','<a>',opt[2]),0)
	return false

end
function Eventing_onConsoleCmd(cmd)

	-- INFO('Debug','call event -> onConsoleCmd')

	local opt = StrSplit(cmd,' ')
	if opt[1] ~= MainCmd then return end

	-- [ ] main cmd.
	if opt[2] == nil then
		INFO('The server is running iLand v'..Plugin.version)
		INFO('Github: https://github.com/LiteLDev-LXL/iLand-Core')

		return false
	end

	-- [op] add land operator.
	if opt[2] == 'op' then
		local name = StrSplit(string.sub(cmd,string.len(MainCmd.." op ")+1),'"')[1]
		local xuid = data.name2xuid(name)
		if xuid == "" then
			ERROR(_Tr('console.landop.failbyxuid','<a>',name))
			return
		end
		if ILAPI.IsLandOperator(xuid) then
			ERROR(_Tr('console.landop.add.failbyexist','<a>',name))
			return
		end
		table.insert(cfg.manager.operator,#cfg.manager.operator+1,xuid)
		UpdateLandOperatorsMap()
		ILAPI.save({1,0,0})
		INFO('System',_Tr('console.landop.add.success','<a>',name,'<b>',xuid))
		return false
	end

	-- [deop] delete land operator.
	if opt[2] == 'deop' then
		local name = StrSplit(string.sub(cmd,string.len(MainCmd.." deop ")+1),'"')[1]
		local xuid = data.name2xuid(name)
		if xuid == "" then
			ERROR(_Tr('console.landop.failbyxuid','<a>',name))
			return
		end
		if not(ILAPI.IsLandOperator(xuid)) then
			ERROR(_Tr('console.landop.del.failbynull','<a>',name))
			return
		end
		table.remove(cfg.manager.operator,FoundValueInList(cfg.manager.operator,xuid))
		UpdateLandOperatorsMap()
		ILAPI.save({1,0,0})
		INFO('System',_Tr('console.landop.del.success','<a>',name,'<b>',xuid))
		return false
	end

	-- [update] Upgrade iLand
	if opt[2] == 'update' then
		if cfg.update_check then
			Upgrade(Server.memInfo)
		else
			ERROR(_Tr('console.update.nodata'))
		end
		return false
	end

	-- [language] Manager for i18n.
	if opt[2] == 'language' then
		local langpath = DATA_PATH..'lang\\'
		if opt[3] == nil then -- no child-command.
			INFO('I18N',_Tr('console.languages.sign','<a>',cfg.manager.default_language,'<b>',_Tr('VERSION')))
			local isNone = false
			local count = 1
			while(not(isNone)) do
				if LangPack['#'..count] ~= nil then
					INFO('I18N',_Tr('#'..count))
				else
					isNone = true
				end
				count = count + 1
			end
		end
		if opt[3] == 'set' then -- set language
			if opt[4] == nil then
				ERROR(_Tr('console.languages.set.misspara'))
				return false;
			end
			local path = langpath..opt[4]..'.json'
			if File.exists(path) then
				cfg.manager.default_language = opt[4]
				LangPack = JSON.decode(file.readFrom(path))
				ILAPI.save({1,0,0})
				INFO(_Tr('console.languages.set.succeed','<a>',cfg.manager.default_language))
			else
				ERROR(_Tr('console.languages.set.nofile','<a>',opt[4]))
			end
		end
		if opt[3] == 'list' then
			local langlist = ILAPI.GetLanguageList(0)
			for i,lang in pairs(langlist) do
				if lang==cfg.manager.default_language then
					INFO('I18N',lang..' <- Using.')
				else
					INFO('I18N',lang)
				end
			end
			INFO('I18N',_Tr('console.languages.list.count','<a>',#langlist))
		end
		if opt[3] == 'list-online' then
			INFO('Network',_Tr('console.languages.list-online.wait'))
			local rawdata = ILAPI.GetLanguageList(1)
			if rawdata == false then
				return false
			end
			INFO('I18N',_Tr('console.languages.official'))
			for i,lang in pairs(rawdata.official) do
				INFO('I18N',lang)
			end
			INFO('I18N',_Tr('console.languages.3rd'))
			for i,lang in pairs(rawdata['3-rd']) do
				INFO('I18N',lang)
			end
		end
		if opt[3] == 'install' then
			if opt[4] == nil then
				ERROR(_Tr('console.languages.install.misspara'))
				return false
			end
			INFO('Network',_Tr('console.languages.list-online.wait'))
			local rawdata = ILAPI.GetLanguageList(1)
			if rawdata == false then
				return false
			end
			if FoundValueInList(ILAPI.GetLanguageList(0),opt[4])~=-1 then
				ERROR(_Tr('console.languages.install.existed'))
				return false
			end
			if FoundValueInList(rawdata.official,opt[4])==-1 and FoundValueInList(rawdata['3-rd'],opt[4])==-1 then
				ERROR(_Tr('console.languages.install.notfound','<a>',opt[4]))
				return false
			end
			INFO(_Tr('console.autoupdate.download'))
			if DownloadLanguage(opt[4]) then
				INFO(_Tr('console.languages.install.succeed','<a>',opt[4]))
			end
		end
		if opt[3] == 'update' then
			local langlist = ILAPI.GetLanguageList(0)
			local langlist_o = ILAPI.GetLanguageList(1)
			local function updateLang(lang)
				local langdata
				if File.exists(langpath..lang..'.json') then
					langdata = JSON.decode(file.readFrom(langpath..lang..'.json'))
				else
					ERROR(_Tr('console.languages.update.notfound','<a>',lang))
					return false -- this false like 'fail'
				end
				if langdata.VERSION == Plugin.numver then
					ERROR(lang..': '.._Tr('console.languages.update.alreadylatest'))
					return true -- continue
				end
				if FoundValueInList(langlist,lang)==-1 then
					ERROR(_Tr('console.languages.update.notfound','<a>',lang))
					return false
				end
				if FoundValueInList(langlist_o.official,lang)==-1 and FoundValueInList(langlist_o['3-rd'],lang)==-1 then
					ERROR(_Tr('console.languages.update.notfoundonline','<a>',lang))
					return false
				end
				if DownloadLanguage(lang) then
					INFO(_Tr('console.languages.update.succeed','<a>',lang))
				end
			end
			if opt[4] == nil then
				INFO(_Tr('console.languages.update.all'))
				for i,lang in pairs(langlist) do
					if not(updateLang(lang)) then
						return false
					end
				end
			else
				INFO(_Tr('console.languages.update.single','<a>',opt[4]))
				updateLang(opt[4])
			end

		end
		return false
	end

	-- [repair] Repairing tools for iland
	-- [repair checkall] Check iland
	-- [repair apply <N>] Try repair the problem

	-- [X] Unknown key
	ERROR('Unknown parameter: "'..opt[2]..'", plugin wiki: https://git.io/JcvIw')
	return false

end
function Eventing_onDestroyBlock(player,block)

	if ChkNil(player) or ILAPI.IsDisabled('onDestroyBlock') then
		return
	end

	local xuid=player.xuid

	if MEM[xuid].selectool==0 then
		local HandItem = player:getHand()
		if HandItem.isNull(HandItem) then goto PROCESS_1 end --fix crash
		SendText(player,_Tr('title.oplandmgr.setsuccess','<a>',HandItem.name))
		cfg.features.selection_tool=HandItem.type
		ILAPI.save({1,0,0})
		MEM[xuid].selectool=-1
		return false
	end

	:: PROCESS_1 ::
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	if land_data[landId].permissions.allow_destroy then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onStartDestroyBlock(player,block)

	if ChkNil(player) then
		return
	end

	local xuid = player.xuid
	local new = (MEM[xuid].newLand~=nil)
	local res = (MEM[xuid].reselectLand~=nil)

	if new or res then
		local HandItem = player:getHand()
		if HandItem:isNull() or HandItem.type~=cfg.features.selection_tool then return end
		if new then
			BoughtProg_SelectRange(player,block.pos,MEM[xuid].newLand.step)
		else
			ReselectLand_Do(player,block.pos,MEM[xuid].reselectLand.step)
		end
	end

end
function Eventing_onPlaceBlock(player,block)

	if ChkNil(player) or ILAPI.IsDisabled('onPlaceBlock') then
		return
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_place then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onUseItemOn(player,item,block)

	if ChkNil(player) or ILAPI.IsDisabled('onUseItemOn') then
		return
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	local perm = land_data[landId].permissions -- Temp perm.
	if perm.useitem then return false end

	local IsConPlus=false
	if not(ILAPI.CanControl(0,block.type)) then 
		if not(ILAPI.CanControl(2,item.type)) then
			return
		else
			IsConPlus=true
		end
	end
	
	if IsConPlus then
		local it = item.type
		if string.sub(it,-6,-1) == 'bucket' and perm.use_bucket then return end -- 各种桶
		if it == 'minecraft:glow_ink_sac' and perm.allow_place then return end -- 发光墨囊给木牌上色（拓充）
		if it == 'minecraft:end_crystal' and perm.allow_place then return end -- 末地水晶（拓充）
		if it == 'minecraft:ender_eye' and perm.allow_place then return end -- 放置末影之眼（拓充）
		if it == 'minecraft:flint_and_steel' and perm.use_firegen then return end -- 使用打火石
	else
		local bn = block.type
		if string.sub(bn,-6,-1) == 'button' and perm.use_button then return end -- 各种按钮
		if bn == 'minecraft:bed' and perm.use_bed then return end -- 床
		if (bn == 'minecraft:chest' or bn == 'minecraft:trapped_chest') and perm.allow_open_chest then return end -- 箱子&陷阱箱
		if bn == 'minecraft:crafting_table' and perm.use_crafting_table then return end -- 工作台
		if (bn == 'minecraft:campfire' or bn == 'minecraft:soul_campfire') and perm.use_campfire then return end -- 营火（烧烤）
		if bn == 'minecraft:composter' and perm.use_composter then return end -- 堆肥桶（放置肥料）
		if (bn == 'minecraft:undyed_shulker_box' or bn == 'minecraft:shulker_box') and perm.use_shulker_box then return end -- 潜匿箱
		if bn == 'minecraft:noteblock' and perm.use_noteblock then return end -- 音符盒（调音）
		if bn == 'minecraft:jukebox' and perm.use_jukebox then return end -- 唱片机（放置/取出唱片）
		if bn == 'minecraft:bell' and perm.use_bell then return end -- 钟（敲钟）
		if (bn == 'minecraft:daylight_detector_inverted' or bn == 'minecraft:daylight_detector') and perm.use_daylight_detector then return end -- 光线传感器（切换日夜模式）
		if bn == 'minecraft:lectern' and perm.use_lectern then return end -- 讲台
		if bn == 'minecraft:cauldron' and perm.use_cauldron then return end -- 炼药锅
		if bn == 'minecraft:lever' and perm.use_lever then return end -- 拉杆
		if bn == 'minecraft:respawn_anchor' and perm.use_respawn_anchor then return end -- 重生锚（充能）
		if string.sub(bn,-4,-1) == 'door' and perm.use_door then return end -- 各种门
		if string.sub(bn,-10,-1) == 'fence_gate' and perm.use_fence_gate then return end -- 各种栏栅门
		if string.sub(bn,-8,-1) == 'trapdoor' and perm.use_trapdoor then return end -- 各种活板门
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onAttack(player,entity)
	
	if ChkNil_X2(player,entity) or ILAPI.IsDisabled('onAttack') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	local perm=land_data[landId].permissions
	local en=entity.type
	local IsConPlus = false
	if ILAPI.CanControl(3,en) then IsConPlus=true end
	local entityType = EntityGetType(en)
	if IsConPlus then
		if en == 'minecraft:ender_crystal' and perm.allow_destroy then return end -- 末地水晶（拓充）
		if en == 'minecraft:armor_stand' and perm.allow_destroy then return end -- 盔甲架（拓充）
	else
		if perm.allow_attack_player and entityType==0 then return end -- Perm Allow
		if perm.allow_attack_animal and entityType==1 then return end
		if perm.allow_attack_mobs and entityType==2 then return end
	end
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onTakeItem(player,entity)

	if ChkNil_X2(player,entity) or ILAPI.IsDisabled('onTakeItem') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_pickupitem then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onDropItem(player,item)

	if ChkNil(player) or ILAPI.IsDisabled('onDropItem') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(player.blockPos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_dropitem then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onBlockInteracted(player,block)

	if ChkNil(player) or ILAPI.IsDisabled('onBlockInteracted') then
		return
	end

	if not(ILAPI.CanControl(1,block.type)) then return end
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	local perm = land_data[landId].permissions
	local bn = block.type
	if bn == 'minecraft:cartography_table' and perm.use_cartography_table then return end -- 制图台
	if bn == 'minecraft:smithing_table' and perm.use_smithing_table then return end -- 锻造台
	if bn == 'minecraft:furnace' and perm.use_furnace then return end -- 熔炉
	if bn == 'minecraft:blast_furnace' and perm.use_blast_furnace then return end -- 高炉
	if bn == 'minecraft:smoker' and perm.use_smoker then return end -- 烟熏炉
	if bn == 'minecraft:brewing_stand' and perm.use_brewing_stand then return end -- 酿造台
	if bn == 'minecraft:anvil' and perm.use_anvil then return end -- 铁砧
	if bn == 'minecraft:grindstone' and perm.use_grindstone then return end -- 磨石
	if bn == 'minecraft:enchanting_table' and perm.use_enchanting_table then return end -- 附魔台
	if bn == 'minecraft:barrel' and perm.use_barrel then return end -- 桶
	if bn == 'minecraft:beacon' and perm.use_beacon then return end -- 信标
	if bn == 'minecraft:hopper' and perm.use_hopper then return end -- 漏斗
	if bn == 'minecraft:dropper' and perm.use_dropper then return end -- 投掷器
	if bn == 'minecraft:dispenser' and perm.use_dispenser then return end -- 发射器
	if bn == 'minecraft:loom' and perm.use_loom then return end -- 织布机
	if bn == 'minecraft:stonecutter_block' and perm.use_stonecutter then return end -- 切石机
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onUseFrameBlock(player,block)
		
	if ChkNil(player) or ILAPI.IsDisabled('onUseFrameBlock') then
		return
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.use_item_frame then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onSpawnProjectile(splasher,type)
			
	if ChkNil(splasher) or ILAPI.IsDisabled('onSpawnProjectile') then
		return
	end

	if splasher:toPlayer()==nil then return end
	local landId=ILAPI.PosGetLand(FixBp(splasher.blockPos))
	if landId==-1 then return end -- No Land

	local player=splasher:toPlayer()
	local xuid=player.xuid
	local perm=land_data[landId].permissions

	if type == 'minecraft:fishing_hook' and perm.use_fishing_hook then return end -- 钓鱼竿
	if type == 'minecraft:splash_potion' and perm.allow_throw_potion then return end -- 喷溅药水
	if type == 'minecraft:lingering_potion' and perm.allow_throw_potion then return end -- 滞留药水
	if type == 'minecraft:thrown_trident' and perm.allow_shoot then return end -- 三叉戟
	if type == 'minecraft:arrow' and perm.allow_shoot then return end -- 弓&弩（箭）
	if type == 'minecraft:snowball' and perm.allow_dropitem then return end -- 雪球
	if type == 'minecraft:ender_pearl' and perm.allow_dropitem then return end -- 末影珍珠
	if type == 'minecraft:egg' and perm.allow_dropitem then return end -- 鸡蛋

	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onFireworkShootWithCrossbow(player)
			
	if ChkNil(player) or ILAPI.IsDisabled('onFireworkShootWithCrossbow') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(player.blockPos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_shoot then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onStepOnPressurePlate(entity,block)
				
	if ChkNil(entity) or ILAPI.IsDisabled('onStepOnPressurePlate') then
		return
	end

	local ispl=false
	local player
	if entity:toPlayer()~=nil then
		ispl=true
		player=entity:toPlayer()
	end

	if entity.pos==nil then -- what a silly mojang?
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land
	
	if land_data[landId].permissions.use_pressure_plate then return end -- Perm Allow
	if ispl then
		local xuid=player.xuid
		if ILAPI.IsLandOperator(xuid) then return end
		if ILAPI.IsLandOwner(landId,xuid) then return end
		if ILAPI.IsPlayerTrusted(landId,xuid) then return end
		SendText(player,_Tr('title.landlimit.noperm'))
	end
	return false
end
function Eventing_onRide(rider,entity)
				
	if ChkNil_X2(rider,entity) or ILAPI.IsDisabled('onRide') then
		return
	end

	if rider:toPlayer()==nil then return end

	local landId=ILAPI.PosGetLand(FixBp(rider.blockPos))
	if landId==-1 then return end -- No Land 

	local player=rider:toPlayer()
	local xuid=player.xuid
	local en=entity.type
	if en=='minecraft:minecart' or en=='minecraft:boat' then
		if land_data[landId].permissions.allow_ride_trans then return end
	else
		if land_data[landId].permissions.allow_ride_entity then return end
	end

	 -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end
function Eventing_onWitherBossDestroy(witherBoss,AAbb,aaBB)

	if ILAPI.IsDisabled('onWitherBossDestroy') then
		return
	end

	local dimid = witherBoss.pos.dimid
	for n,pos in pairs(TraverseAABB(AAbb,aaBB,dimid)) do
		local landId=ILAPI.PosGetLand(pos)
		if landId~=-1 and not(land_data[landId].permissions.allow_entity_destroy) then 
			break
		end
	end
	return false
end
function Eventing_onExplode(entity,pos)

	if ChkNil(entity) or ILAPI.IsDisabled('onExplode') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_explode then return end -- EV Allow
	return false
end
function Eventing_onBedExplode(pos)

	if ILAPI.IsDisabled('onBedExplode') then
		return
	end

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_explode then return end -- EV Allow
	return false
end
function Eventing_onRespawnAnchorExplode(pos,player)

	if ILAPI.IsDisabled('onRespawnAnchorExplode') then
		return
	end

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_explode then return end -- EV Allow
	return false
end
function Eventing_onFarmLandDecay(pos,entity)
	
	if ChkNil(entity) or ILAPI.IsDisabled('onFarmLandDecay') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_farmland_decay then return end -- EV Allow
	return false
end
function Eventing_onPistonPush(pos,block)

	if ILAPI.IsDisabled('onPistonPush') then
		return
	end

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_piston_push then return end -- Perm Allow
	return false
end
function Eventing_onFireSpread(pos)

	if ILAPI.IsDisabled('onFireSpread') then
		return
	end

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_fire_spread then return end -- Perm Allow
	return false
end

-- Lua -> Timer Callback
function Tcb_LandSign()
	for xuid,data in pairs(MEM) do
		local player=mc.getPlayer(xuid)

		if ChkNil(player) then
			goto JUMPOUT_SIGN
		end

		local xuid = player.xuid
		local landId=ILAPI.PosGetLand(FixBp(player.blockPos))
		if landId==-1 then MEM[xuid].inland='null';goto JUMPOUT_SIGN end -- no land here
		if landId==MEM[xuid].inland then goto JUMPOUT_SIGN end -- signed

		local ownerXuid=ILAPI.GetOwner(landId)
		local ownerId = '?'
		if ownerXuid~='?' then ownerId=data.xuid2name(ownerXuid) end
		
		if xuid==ownerXuid then 
			-- land owner in land.
			if not(land_data[landId].settings.signtome) then
				goto JUMPOUT_SIGN
			end
			SendTitle(player,
				_Tr('sign.listener.ownertitle','<a>',ILAPI.GetNickname(landId,false)),
				_Tr('sign.listener.ownersubtitle')
			)
		else  
			-- visitor in land
			if not(land_data[landId].settings.signtother) then
				goto JUMPOUT_SIGN
			end
			SendTitle(player,
				_Tr('sign.listener.visitortitle'),
				_Tr('sign.listener.visitorsubtitle','<a>',ownerId)
			)
			if land_data[landId].settings.describe~='' then
				local des = CloneTable(land_data[landId].settings.describe)
				des = string.gsub(des,'$visitor',player.realName)
				des = string.gsub(des,'$n','\n')
				SendText(player,des,0)
			end
		end
		MEM[xuid].inland = landId
		:: JUMPOUT_SIGN ::
	end
end
function Tcb_ButtomSign()
	for xuid,data in pairs(MEM) do
		local player=mc.getPlayer(xuid)

		if ChkNil(player) then
			goto JUMPOUT_BUTTOM
		end

		local landId = ILAPI.PosGetLand(FixBp(player.blockPos))
		if landId==-1 then
			goto JUMPOUT_BUTTOM
		end

		local ownerXuid = ILAPI.GetOwner(landId)
		local ownerName = '?'
		if ownerXuid~='?' then ownerName=data.xuid2name(ownerXuid) end
		local landcfg = land_data[landId].settings
		if (xuid==ownerXuid) and landcfg.signtome and landcfg.signbuttom then
			player:sendText(_Tr('title.landsign.ownenrbuttom','<a>',ILAPI.GetNickname(landId)),4)
		end
		if (xuid~=ownerXuid) and landcfg.signtother and landcfg.signbuttom then
			player:sendText(_Tr('title.landsign.visitorbuttom','<a>',ownerName),4)
		end

		:: JUMPOUT_BUTTOM ::
	end
end
function Timer_MEM()
	for xuid,res in pairs(MEM) do
		if cfg.features.particles and res.particles ~= nil then -- Keeping Particles
			local Tpos = mc.getPlayer(xuid).blockPos
			for n,pos in pairs(res.particles) do
				local posY
				if MEM[xuid].newLand~=nil then
					if MEM[xuid].newLand.dimension=='2D' then
						posY = Tpos.y + 2
					else
						posY = pos.y + 1.6
					end
				end
				if MEM[xuid].reselectLand~=nil then
					posY = pos.y
				end
				mc.runcmdEx('execute @a[name="'..data.xuid2name(xuid)..'"] ~ ~ ~ particle "'..cfg.features.particle_effects..'" '..pos.x..' '..posY..' '..pos.z)
			end
		end
		if res.keepingTitle ~= nil then -- Keeping Title
			local title = res.keepingTitle
			if type(title)=='table' then
				SendTitle(mc.getPlayer(xuid),title[1],title[2],{0,40,20})
			else
				SendTitle(mc.getPlayer(xuid),title,{0,100,0})
			end
		end
	end
end

-- listen events,
mc.listen('onPlayerCmd',Eventing_onPlayerCmd)
mc.listen('onConsoleCmd',Eventing_onConsoleCmd)
mc.listen('onJoin',Eventing_onJoin)
mc.listen('onPreJoin',Eventing_onPreJoin)
mc.listen('onLeft',Eventing_onLeft)
mc.listen('onDestroyBlock',Eventing_onDestroyBlock)
mc.listen('onPlaceBlock',Eventing_onPlaceBlock)
mc.listen('onUseItemOn',Eventing_onUseItemOn)
mc.listen('onAttack',Eventing_onAttack)
mc.listen('onExplode',Eventing_onExplode)
mc.listen('onBedExplode',Eventing_onBedExplode)
mc.listen('onRespawnAnchorExplode',Eventing_onRespawnAnchorExplode)
mc.listen('onTakeItem',Eventing_onTakeItem)
mc.listen('onDropItem',Eventing_onDropItem)
mc.listen('onBlockInteracted',Eventing_onBlockInteracted)
mc.listen('onUseFrameBlock',Eventing_onUseFrameBlock)
mc.listen('onSpawnProjectile',Eventing_onSpawnProjectile)
mc.listen('onFireworkShootWithCrossbow',Eventing_onFireworkShootWithCrossbow)
mc.listen('onStepOnPressurePlate',Eventing_onStepOnPressurePlate)
mc.listen('onRide',Eventing_onRide)
mc.listen('onWitherBossDestroy',Eventing_onWitherBossDestroy)
mc.listen('onFarmLandDecay',Eventing_onFarmLandDecay)
mc.listen('onPistonPush',Eventing_onPistonPush)
mc.listen('onFireSpread',Eventing_onFireSpread)
mc.listen('onStartDestroyBlock',Eventing_onStartDestroyBlock)

-- timer -> landsign|particles|debugger
function EnableLandsign()
	CLOCK_LANDSIGN = setInterval(Tcb_LandSign,cfg.features.sign_frequency*1000)
	BUTTOM_SIGN = setInterval(Tcb_ButtomSign,cfg.features.sign_frequency*500)
end

-- check update
function Ncb_online(code,result)
	if code==200 then
		local data = JSON.decode(result)

		Server.memInfo = data

		-- Check File Version
		if data.FILE_Version~=202 then
			INFO('Network',_Tr('console.getonline.failbyver','<a>',data.FILE_Version))
			return
		end

		-- Check Update
		if Plugin.numver<data.Updates[1].NumVer then
			INFO('Network',_Tr('console.update.newversion','<a>',data.Updates[1].Version))
			INFO('Update',_Tr('console.update.newcontent'))
			for n,text in pairs(data.Updates[1].Description) do
				INFO('Update',n..'. '..text)
			end
			if data.Force_Update then
				INFO('Update',_Tr('console.update.force'))
				Upgrade(data)
			end
			if cfg.features.auto_update then
				INFO('Update',_Tr('console.update.auto'))
				Upgrade(data)
			end
		end
		if Plugin.numver>data.Updates[1].NumVer then
			INFO('Network',_Tr('console.update.preview','<a>',Plugin.version))
		end
	else
		ERROR(_Tr('console.getonline.failbycode','<a>',code))
	end
end

mc.listen('onServerStarted',function()
	local function throwErr(x)
		if x==-1 then
			ERROR('Configure file not found.')
		end
		if x==-2 then
			ERROR('LiteXLoader too old, please use latest version, here ↓')
			ERROR('https://www.minebbs.com/')
		end
		if x==-4 then
			ERROR('Language file does not match version. (!='..Plugin.numver..')')
		end
		ERROR('Plugin closing...')
		mc.runcmd('stop')
	end

	-- Check file
	if not(file.exists(DATA_PATH..'config.json')) then
		throwErr(-1)
	end
	if not(file.exists(DATA_PATH..'data.json')) then
		file.writeTo(DATA_PATH..'data.json','{}')
	end
	if not(file.exists(DATA_PATH..'owners.json')) then
		file.writeTo(DATA_PATH..'owners.json','{}')
	end
	
	-- Check depends version
	if not(lxl.checkVersion(Plugin.minLXL[1],Plugin.minLXL[2],Plugin.minLXL[3])) then
		throwErr(-2)
	end

	-- Load data file
	cfg = JSON.decode(file.readFrom(DATA_PATH..'config.json'))
	LangPack = JSON.decode(file.readFrom(DATA_PATH..'lang\\'..cfg.manager.default_language..'.json'))
	if LangPack.VERSION ~= Plugin.numver then
		throwErr(-4)
	end
	land_data = JSON.decode(file.readFrom(DATA_PATH..'data.json'))
	land_owners = {}
	wrong_landowners = {}
	local itHasWrongXuid = false
	for ownerXuid,landIds in pairs(JSON.decode(file.readFrom(DATA_PATH..'owners.json'))) do
		if data.xuid2name(ownerXuid) == '' then
			ERROR(_Tr('console.error.readowner.xuid','<a>',ownerXuid))
			wrong_landowners[ownerXuid] = landIds
			itHasWrongXuid = true
		else
			land_owners[ownerXuid] = landIds
		end
	end

	if itHasWrongXuid then
		INFO('TIP',_Tr('console.error.readowner.tipxid'))
	end

	-- Configure Updater
	do
		if cfg.version==nil or cfg.version<200 then
			ERROR('Configure file too old, you must rebuild it.')
			return
		end
		if cfg.version==200 then
			cfg.version=210
			cfg.money.credit_name='Gold-Coins'
			cfg.money.discount=100
			cfg.features.land_2D=true
			cfg.features.land_3D=true
			cfg.features.auto_update=true
			for landId,data in pairs(land_data) do
				land_data[landId].range.dimid = CloneTable(land_data[landId].range.dim)
				land_data[landId].range.dim=nil
				for n,xuid in pairs(land_data[landId].settings.share) do
					if type(xuid)~='string' then
						land_data[landId].settings.share[n]=tostring(land_data[landId].settings.share[n])
					end
				end
			end
			ILAPI.save({1,1,0})
		end
		if cfg.version==210 then
			cfg.version=211
			local landbuy=cfg.land_buy
			landbuy.calculation_3D='m-1'
			landbuy.calculation_2D='d-1'
			landbuy.price_3D={20,4}
			landbuy.price_2D={35}
			landbuy.price=nil
			landbuy.calculation=nil
			ILAPI.save({1,0,0})
		end
		if cfg.version==211 then
			cfg.version=220
			cfg.features.offlinePlayerInList=true
			for landId,data in pairs(land_data) do
				local perm=land_data[landId].permissions
				perm.use_lever=false
				perm.use_button=false
				perm.use_respawn_anchor=false
				perm.use_item_frame=false
				perm.use_fishing_hook=false
				perm.use_pressure_plate=false
				perm.allow_throw_potion=false
				perm.allow_ride_entity=false
				perm.allow_ride_trans=false
				perm.allow_shoot=false
				local settings=land_data[landId].settings
				settings.ev_explode=CloneTable(perm.allow_exploding)
				settings.ev_farmland_decay=false
				settings.ev_piston_push=false
				settings.ev_fire_spread=false
				settings.signbuttom=true
				perm.use_door=false
				perm.use_stonecutter=false
				perm.allow_exploding=nil
			end
			ILAPI.save({1,1,0})
		end
		if cfg.version==220 or cfg.version==221 then
			cfg.version=223
			ILAPI.save({1,0,0})
		end
		if cfg.version==223 then
			cfg.version=224
			for landId,data in pairs(land_data) do
				land_data[landId].permissions.use_bucket=false
			end
			ILAPI.save({1,1,0})
		end
		if cfg.version==224 then
			cfg.version=230
			cfg.features.disabled_listener = {}
			cfg.features.blockLandDims = {}
			cfg.features.nearby_protection = {
				side = 10,
				enabled = true,
				blockselectland = true
			}
			cfg.features.regFakeCmd=true
			cfg.features.playersPerPage=20
			for landId,data in pairs(land_data) do
				local perm = land_data[landId].permissions
				if data.range.start_position.y==0 and data.range.end_position.y==255 then
					land_data[landId].range.start_position.y=minY
					land_data[landId].range.start_position.y=maxY
				end
				perm.use_firegen=false
				perm.allow_attack=nil
				perm.allow_attack_player=false
				perm.allow_attack_animal=false
				perm.allow_attack_mobs=true
			end
			ILAPI.save({1,1,0})
		end
		if cfg.version==230 then
			cfg.version=231
			cfg.verison=nil -- sb..
			for landId,data in pairs(land_data) do
				local perm = land_data[landId].permissions
				if #perm~=50 then
					INFO('AutoRepair','Land <'..landId..'> Has wrong perm cfg, resetting...')
					perm.allow_destroy=false
					perm.allow_place=false
					perm.allow_attack_player=false
					perm.allow_attack_animal=false
					perm.allow_attack_mobs=true
					perm.allow_open_chest=false
					perm.allow_pickupitem=false
					perm.allow_dropitem=true
					perm.use_anvil = false
					perm.use_barrel = false
					perm.use_beacon = false
					perm.use_bed = false
					perm.use_bell = false
					perm.use_blast_furnace = false
					perm.use_brewing_stand = false
					perm.use_campfire = false
					perm.use_firegen = false
					perm.use_cartography_table = false
					perm.use_composter = false
					perm.use_crafting_table = false
					perm.use_daylight_detector = false
					perm.use_dispenser = false
					perm.use_dropper = false
					perm.use_enchanting_table = false
					perm.use_door=false
					perm.use_fence_gate = false
					perm.use_furnace = false
					perm.use_grindstone = false
					perm.use_hopper = false
					perm.use_jukebox = false
					perm.use_loom = false
					perm.use_stonecutter = false
					perm.use_noteblock = false
					perm.use_shulker_box = false
					perm.use_smithing_table = false
					perm.use_smoker = false
					perm.use_trapdoor = false
					perm.use_lectern = false
					perm.use_cauldron = false
					perm.use_lever=false
					perm.use_button=false
					perm.use_respawn_anchor=false
					perm.use_item_frame=false
					perm.use_fishing_hook=false
					perm.use_bucket=false
					perm.use_pressure_plate=false
					perm.allow_throw_potion=false
					perm.allow_ride_entity=false
					perm.allow_ride_trans=false
					perm.allow_shoot=false
				end
			end
			ILAPI.save({1,1,0})
		end
		if cfg.version==231 then
			cfg.version=240
			for landId,data in pairs(land_data) do
				local perm = land_data[landId].permissions
				perm.allow_entity_destroy=false
				perm.useitem=false
			end
			ILAPI.save({1,1,0})
		end
	end
	
	-- Build maps
	BuildAnyMap()

	-- Make timer
	if cfg.features.landSign then
		EnableLandsign()
	end
	setInterval(Timer_MEM,1000)

	-- Check Update
	if cfg.update_check then
		local server = GetLink()
		if server ~=  false then
			network.httpGet(server..'/server.json',Ncb_online)
		else
			ERROR(_Tr('console.getonline.failed'))
		end
	end

	-- register cmd.
	if cfg.features.regFakeCmd then
		mc.regPlayerCmd(MainCmd,_Tr('command.land'),F_NULL)
		mc.regPlayerCmd(MainCmd..' new',_Tr('command.land_new'),F_NULL)
		mc.regPlayerCmd(MainCmd..' giveup',_Tr('command.land_giveup'),F_NULL)
		mc.regPlayerCmd(MainCmd..' gui',_Tr('command.land_gui'),F_NULL)
		mc.regPlayerCmd(MainCmd..' a',_Tr('command.land_a'),F_NULL)
		mc.regPlayerCmd(MainCmd..' b',_Tr('command.land_b'),F_NULL)
		mc.regPlayerCmd(MainCmd..' buy',_Tr('command.land_buy'),F_NULL)
		mc.regPlayerCmd(MainCmd..' mgr',_Tr('command.land_mgr'),F_NULL)
		mc.regPlayerCmd(MainCmd..' mgr selectool',_Tr('command.land_mgr_selectool'),F_NULL)
		if cfg.features.landtp then
			mc.regPlayerCmd(MainCmd..' tp',_Tr('command.land_tp'),F_NULL)
			mc.regPlayerCmd(MainCmd..' tp set',_Tr('command.land_tp_set'),F_NULL)
			mc.regPlayerCmd(MainCmd..' tp rm',_Tr('command.land_tp_rm'),F_NULL)
		end
		mc.regConsoleCmd(MainCmd,_Tr('command.console.land'),F_NULL)
	end

end)

-- export function
lxl.export(ILAPI.CreateLand,'ILAPI_CreateLand')
lxl.export(ILAPI.DeleteLand,'ILAPI_DeleteLand')
lxl.export(ILAPI.PosGetLand,'ILAPI_PosGetLand')
lxl.export(ILAPI.GetChunk,'ILAPI_GetChunk')
lxl.export(ILAPI.GetAllLands,'ILAPI_GetAllLands')
lxl.export(ILAPI.CheckPerm,'ILAPI_CheckPerm')
lxl.export(ILAPI.CheckSetting,'ILAPI_CheckSetting')
lxl.export(ILAPI.GetRange,'ILAPI_GetRange')
lxl.export(ILAPI.GetEdge,'ILAPI_GetEdge')
lxl.export(ILAPI.GetDimension,'ILAPI_GetDimension')
lxl.export(ILAPI.GetName,'ILAPI_GetName')
lxl.export(ILAPI.GetDescribe,'ILAPI_GetDescribe')
lxl.export(ILAPI.GetOwner,'ILAPI_GetOwner')
lxl.export(ILAPI.GetPoint,'ILAPI_GetPoint')
lxl.export(ILAPI.GetPlayerLands,'ILAPI_GetPlayerLands')
lxl.export(ILAPI.IsPlayerTrusted,'ILAPI_IsPlayerTrusted')
lxl.export(ILAPI.IsLandOwner,'ILAPI_IsLandOwner')
lxl.export(ILAPI.IsLandOperator,'ILAPI_IsLandOperator')
lxl.export(ILAPI.GetAllTrustedLand,'ILAPI_GetAllTrustedLand')
lxl.export(ILAPI.UpdatePermission,'ILAPI_UpdatePermission')
lxl.export(ILAPI.UpdateSetting,'ILAPI_UpdateSetting')
lxl.export(ILAPI.AddTrust,'ILAPI_AddTrust')
lxl.export(ILAPI.RemoveTrust,'ILAPI_RemoveTrust')
lxl.export(ILAPI.SetOwner,'ILAPI_SetOwner')
lxl.export(ILAPI.GetMoneyProtocol,'ILAPI_GetMoneyProtocol')
lxl.export(ILAPI.GetLanguage,'ILAPI_GetLanguage')
lxl.export(ILAPI.GetChunkSide,'ILAPI_GetChunkSide')
lxl.export(ILAPI.GetVersion,'ILAPI_GetVersion')

INFO('Powerful land plugin is loaded! Ver-'..Plugin.version..',')
INFO('By: RedbeanW, License: GPLv3 with additional conditions.')
