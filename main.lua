nova.require "libraries/bresenham"

function ignite_along_line(self, level, source, end_point)
    local start_point = source:get_position()
    local points, _ = line(start_point.x, start_point.y, end_point.x, end_point.y, function (x,y)
        return true
    end)
    local burn_amount = world:get_player().attributes.fireangel_burn or 1
    local burn_slevel = core.get_status_value( burn_amount, "ignite", world:get_player() )
    local flame_amount = world:get_player().attributes.fireangel_flame or 8
    local flame_slevel = core.get_status_value( flame_amount, "ignite", world:get_player() )
    nova.log("Fireangel beam mod checking for targets")
    local burn_point = source:get_position()
    for _, v in ipairs(points) do
        if v.x == start_point.x and v.y == start_point.y then
            nova.log("Fireangel beam mod not igniting player")
        else
            burn_point.x = v.x
            burn_point.y = v.y
            for e in level:entities( burn_point ) do
                nova.log("Fireangel beam mod entity found on line")
                if e.data and e.data.can_burn then
                    nova.log("Fireangel beam mod trying to burn "..e.text.name)
                    core.apply_damage_status( e, "burning", "ignite", burn_slevel, world:get_player())
                end
            end
            nova.log("Fireangel beam mod placing flames x"..burn_point.x..", y"..burn_point.y)
            gtk.place_flames( burn_point, math.max( flame_slevel + math.random(3), 2 ), 300 + math.random(400) + 50 )
        end
    end
end

function debuff_along_line(self, level, source, end_point)
    local start_point = source:get_position()
    local points, _ = line(start_point.x, start_point.y, end_point.x, end_point.y, function (x,y)
        return true
    end)
    local burn_point = source:get_position()
    for _, v in ipairs(points) do
        if v.x == start_point.x and v.y == start_point.y then
            nova.log("Better Fireangel beam mod not debuffing player")
        else
            burn_point.x = v.x
            burn_point.y = v.y
            for e in level:entities( burn_point ) do
                nova.log("Better Fireangel beam mod entity found on line")
                if e.data and e.data.can_burn then
                    nova.log("Better Fireangel beam mod trying to debuff "..e.text.name)
                    local amount = world:get_player().attributes.fireangel_burn or 1
                    local slevel = core.get_status_value( amount, "ignite", world:get_player() )
                    local ihlevel = world:get_player().data.intense_heat
                    if ihlevel == 2 and e.attributes and e:attribute( "resist", "ignite" ) == 50 then
                        world:add_buff( e, "intense_heat_3", (slevel + 2) * 100 )
                    end
                    if e.attributes and e:attribute( "resist", "ignite" ) >= 100 then
                        nova.log("Intense heat duration "..(slevel + 2) * 100)
                        if ihlevel == 1 then
                            world:add_buff( e, "intense_heat_1", (slevel + 2) * 100 )
                        elseif ihlevel == 2 then
                            world:add_buff( e, "intense_heat_2", (slevel + 2) * 100 )
                        end
                    end
                end
            end
        end
    end
end

register_blueprint "intense_heat_1"
{
    flags = { EF_NOPICKUP },
    text = {
        name    = "Intense Heat",
        desc    = "reduces fire resistances to {!50%}",
    },
    callbacks = {
        on_attach = [[
            function( self, parent )
                local ignite_resist = parent:attribute( "resist", "ignite" )
                self.attributes["ignite.resist"] = -1 * ( ignite_resist - 50 )
            end
        ]],
        on_die = [[
            function ( self )
                world:mark_destroy( self )
            end
        ]],
    },
    attributes = {
        resist = {
            ignite = 0,
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
        desc    = "reduces fire resistances to {!10%}",
    },
    callbacks = {
        on_attach = [[
            function( self, parent )
                local ignite_resist = parent:attribute( "resist", "ignite" )
                self.attributes["ignite.resist"] = -1 * ( ignite_resist - 10 )
            end
        ]],
        on_die = [[
            function ( self )
                world:mark_destroy( self )
            end
        ]],
    },
    attributes = {
        resist = {
            ignite = 0,
        },
    },
    ui_buff = {
        color = RED,
    },
}

register_blueprint "intense_heat_3"
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
                nova.log("Using modded fireangel perk - Better Fireangel")
                if not is_repeat then
                    if weapon and weapon.ui_target and weapon.ui_target.type == world:hash("beam") then
                        debuff_along_line(self, level, source, c)
                        ignite_along_line(self, level, source, c)
                    else
                        for e in level:entities( c ) do
                            if e.data and e.data.can_burn then
                                local amount = world:get_player().attributes.fireangel_burn or 1
                                local slevel = core.get_status_value( amount, "ignite", world:get_player() )
                                local ihlevel = world:get_player().data.intense_heat
                                if ihlevel == 2 and e.attributes and e:attribute( "resist", "ignite" ) == 50 then
                                    world:add_buff( e, "intense_heat_3", (slevel + 2) * 100 )
                                end
                                if e.attributes and e:attribute( "resist", "ignite" ) >= 100 then
                                    nova.log("Intense heat duration "..(slevel + 2) * 100)
                                    if ihlevel == 1 then
                                        world:add_buff( e, "intense_heat_1", (slevel + 2) * 100 )
                                    elseif ihlevel == 2 then
                                        world:add_buff( e, "intense_heat_2", (slevel + 2) * 100 )
                                    end
                                end
                                core.apply_damage_status( e, "burning", "ignite", slevel, world:get_player() )
                            end
                        end
                    end
                end
                if distance < 6 then
                    if distance < 1 then distance = 1 end
                    local amount = world:get_player().attributes.fireangel_flame or 8
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
        full   = "You love heat, you're the angel of fire! You shrug off explosions unless you take a direct hit, moreover any wielded weapon you use (especially area of effect weapons) sets the world on fire!\n\n{!LEVEL 1} - {!50%} reduction of splash damage (stacks), {!immunity} to fire status effect, {!1 Burning} stack per hit, {!8 Burning} flame created\n{!LEVEL 2} - splash damage {!immunity}, {!+50%} to {!all} Burning you inflict, fire immune enemies only 50% resist\n{!LEVEL 3} - {!+100%} to {!all} Burning effects you inflict, fire immune enemies only 10% resist\n\nYou can pick only one MASTER trait per character.",
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