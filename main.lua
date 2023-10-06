nova.require "libraries/bresenham"

register_blueprint "intense_heat_1"
{
	flags = { EF_NOPICKUP }, 
	text = {
		name    = "Intense Heat",
		desc    = "reduces fire resistances by {!25%}",
	},
	callbacks = {
		on_die = [[
			function ( self )
				world:mark_destroy( self )
			end
		]],
	},
	attributes = {		
		resist = {			
			ignite = -25,			
		},
	},
	ui_buff = {
		color = RED,
	},
}

register_blueprint "intense_heat_2"
{
	flags = { EF_NOPICKUP }, 
	text = {
		name    = "Intense Heat",
		desc    = "reduces fire resistances by {!50%}",
	},
	callbacks = {
		on_die = [[
			function ( self )
				world:mark_destroy( self )
			end
		]],
	},
	attributes = {		
		resist = {			
			ignite = -50,			
		},
	},
	ui_buff = {
		color = RED,
	},
}

register_blueprint "kperk_fireangel"
{
	flags = { EF_NOPICKUP }, 
	callbacks = {
		on_area_damage = [[
			function ( self, weapon, level, c, damage, distance, center, source, is_repeat )				
				nova.log("Using modded fireangel perk")
				if not is_repeat then					
					if weapon and weapon.ui_target and weapon.ui_target.type == world:hash("beam") then																		
						ignite_along_line(self, level, source, c)						
					else
						for e in level:entities( c ) do
							if e.data and e.data.can_burn then			
								local amount = world:get_player().attributes.fireangel_burn
								local slevel = core.get_status_value( amount, "ignite", world:get_player() )
								local ihlevel = world:get_player().data.intense_heat							
								if e.attributes and e:attribute( "resist", "ignite" ) == 100 then
									if ihlevel == 1 then
										world:add_buff( e, "intense_heat_1", 200 )
									elseif ihlevel == 2 then
										world:add_buff( e, "intense_heat_2", 200 )
									end									
								end								
								core.apply_damage_status( e, "burning", "ignite", slevel, world:get_player() )
							end
						end
					end	
				end
				if distance < 6 then
					if distance < 1 then distance = 1 end
					local amount = world:get_player().attributes.fireangel_flame
					local slevel = core.get_status_value( math.max( amount + 1 - distance, 1 ), "ignite", world:get_player() )
					gtk.place_flames( c, math.max( slevel + math.random(3), 2 ), 300 + math.random(400) + distance * 50 )
				end				
			end
		]],
	},
}

register_blueprint "ktrait_master_fireangel"
{
	blueprint = "trait",
	text = {
		name   = "FIREANGEL",
		desc   = "MASTER TRAIT - splash damage resistance and fire effects. Modded.",
		full   = "You love heat, you're the angel of fire! You shrug off explosions unless you take a direct hit, moreover any wielded weapon you use (especially area of effect weapons) sets the world on fire!\n\n{!LEVEL 1} - {!50%} reduction of splash damage (stacks), {!immunity} to fire status effect, {!1 Burning} stack per hit, {!8 Burning} flame created\n{!LEVEL 2} - splash damage {!immunity}, {!+50%} to {!all} Burning you inflict, 100% fire resist enemies treated as 75% resist\n{!LEVEL 3} - {!+100%} to {!all} Burning effects you inflict, 100% fire resist enemies treated as 50% resist\n\nYou can pick only one MASTER trait per character.",
		abbr   = "MFA",
	},
	attributes = {
		level    = 1,
		affinity = {
			ignite = 0,
		},		
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local tlevel, t = gtk.upgrade_master( entity, "ktrait_master_fireangel" )
				if tlevel == 1 then
					entity.attributes.splash_mod = ( entity.attributes.splash_mod or 1.0 ) * 0.5
					t.attributes["ignite.resist"] = 100
					entity.data.can_burn = false
					entity.attributes.fireangel_burn  = 1
					entity.attributes.fireangel_flame = 8
				elseif tlevel == 2 then
					entity.attributes.splash_mod = 0.0
					t.attributes["ignite.affinity"] = 50
					entity.data.intense_heat = 1
				elseif tlevel == 3 then
					t.attributes["ignite.affinity"] = 100
					entity.data.intense_heat = 2
				end
				if tlevel == 1 then
					local index = 0
					repeat 
						local w = world:get_weapon( entity, index, true )
						if not w then break end
						local fp = w:child("kperk_fireangel")
						if not fp then
							w:attach("kperk_fireangel")
						end
						index = index + 1
					until false
				end
			end
		]=],
		on_pickup = [=[
			function ( self, user, w )
				if user.attributes.fireangel_burn then
					if w and w.weapon and ( not w.stack ) then
						local fp = w:child("kperk_fireangel")
						if not fp then
							w:attach("kperk_fireangel")
						end
					end
				end
			end
		]=],
	},
}