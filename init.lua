-- ==== IMPORTS ====
local waywall = require("waywall")
local helpers = require("waywall.helpers")


-- ==== KEYS ====
local thin = "*-Alt_L"
local tall = "*-H"
local wide = "*-V"

local toggle_ninbot = "*-apostrophe"
local launch_paceman = "Shift-P"
local fullscreen = "Shift-O"

local remapped_kb = {
    -- ["Q"] = "O"
}

-- ==== SENSITIVITIES ====
local normal_sens = 2.8
local tall_sens = 0.006


-- ==== PATHS ====
local home_path = os.getenv("HOME") .. "/"
local pacem_path = home_path .. "mcsr/paceman-tracker-0.7.0.jar"
local nb_path = home_path .. "mcsr/Ninjabrain-Bot-1.5.2.jar"
local overlay_path = home_path .. ".config/waywall/measuring_overlay.png"
local nb_overlay_path = "/tmp/nb-overlay.png"


-- ==== HELPERS ====
local is_ninb_running = function()
    local handle = io.popen("pgrep -f 'Ninjabrain.*jar'")
    local result = handle:read("*l")
    handle:close()
    return result ~= nil
end

local is_pacem_running = function()
    local handle = io.popen("pgrep -f 'paceman..*'")
    local result = handle:read("*l")
    handle:close()
    return result ~= nil
end


-- ==== MIRRORS ====
local make_mirror = function(options)
    local this = nil

    return function(enable)
        if enable and not this then
            this = waywall.mirror(options)
        elseif this and not enable then
            this:close()
            this = nil
        end
    end
end

local mirrors = {
    thin_e = make_mirror({
        src = { x = 0, y = 37, w = 85, h = 9 },
        dst = { x = 1130, y = 618, w = 4 * 85, h = 4 * 9 },
    }),

    tall_e = make_mirror({
        src = { x = 0, y = 37, w = 85, h = 9 },
        dst = { x = 1130, y = 618, w = 4 * 85, h = 4 * 9 },
    }),

    tall_pie = make_mirror({
        src = { x = 0, y = 15958, w = 340, h = 426 },
        dst = { x = 1130, y = 654, w = 340, h = 426 },
    }),

    eye_measure = make_mirror({
        src = { x = 155, y = 7902, w = 30, h = 580 },
        dst = { x = 0, y = 370, w = 790, h = 340 },
    }),
}


-- ==== AUTO-REFRESHING IMAGES ====
local make_image = function(path, dst)
    local this = nil

    return function(enable)
        if enable == nil then
            if this then
                this:close()
                this = nil
            else
                this = waywall.image(path, dst)
            end
        elseif enable and not this then
            this = waywall.image(path, dst)
        elseif not enable and this then
            this:close()
            this = nil
        end
    end
end

-- Generador de imagen con refresco dinámico automático para Ninjabrain Bot
local make_auto_image = function(path, dst, interval_ms)
    local this = nil
    local timer = nil

    local reload = function()
        if this then
            this:close()
            this = waywall.image(path, dst)
        end
    end

    return function(enable)
        if enable == nil then
            if this then
                if timer then timer:cancel() timer = nil end
                this:close()
                this = nil
            else
                this = waywall.image(path, dst)
                timer = waywall.timer(interval_ms, reload, true)
            end
        elseif enable and not this then
            this = waywall.image(path, dst)
            timer = waywall.timer(interval_ms, reload, true)
        elseif not enable and this then
            if timer then timer:cancel() timer = nil end
            this:close()
            this = nil
        end
    end
end

local images = {
    measuring_overlay = make_image(overlay_path, {
        dst = { x = 0, y = 370, w = 790, h = 340 },
    }),
    
    -- Se refresca en pantalla automáticamente cada 100ms si está encendido
    ninb_overlay = make_auto_image(nb_overlay_path, {
        dst = { x = 10, y = 10, w = 280, h = 150 },
    }, 100),
}

local show_mirrors = function(thin, tall, wide)
    mirrors.thin_e(thin)

    mirrors.tall_e(tall)
    mirrors.tall_pie(tall)

    mirrors.eye_measure(tall)
    images.measuring_overlay(tall)
end

local thin_enable = function()
    show_mirrors(true, false, false)
    waywall.set_sensitivity(normal_sens)
end

local tall_enable = function()
    show_mirrors(false, true, false)
    waywall.set_sensitivity(tall_sens)
end

local wide_enable = function()
    show_mirrors(false, false, true)
    waywall.set_sensitivity(normal_sens)
end

local res_disable = function()
    show_mirrors(false, false, false)
    waywall.set_sensitivity(normal_sens)
end


-- ==== RESOLUTIONS ====
local make_res = function(width, height, enable, disable)
    return function()
        local active_width, active_height = waywall.active_res()

        if active_width == width and active_height == height then
            waywall.set_resolution(0, 0)
            disable()
        else
            waywall.set_resolution(width, height)
            enable()
        end
    end
end

local resolutions = {
    thin = make_res(340, 1080, thin_enable, res_disable),
    tall = make_res(340, 16384, tall_enable, res_disable),
    wide = make_res(1920, 340, wide_enable, res_disable),
}


-- ==== CONFIG ====
local config = {
    input = {
        layout = "us",
        repeat_rate = 40,
        repeat_delay = 300,
        remaps = remapped_kb,
        sensitivity = normal_sens,
        confine_pointer = false,
    },
    theme = {
        background = "#00000000",
        ninb_anchor = "topright",
        ninb_opacity = 0.5,
    },
}

config.actions = {
    [thin] = resolutions.thin,
    [tall] = resolutions.tall,
    [wide] = resolutions.wide,

    [toggle_ninbot] = function()
        if not is_ninb_running() then
            waywall.exec("env DISPLAY=:0 java -jar " .. nb_path)
        end

        images.ninb_overlay()
    end,

    [launch_paceman] = function()
        if not is_pacem_running() then
            waywall.exec("java -jar " .. pacem_path .. " --nogui")
        end
    end,

    [fullscreen] = waywall.toggle_fullscreen,
}

return config
