local Style = "Automatic"
local Settings = {
        Method = "Firesignal",
        SickChance = 100,
        GoodChance = 0,
        OkChance = 0,
        BadChance = 0,
        MissChance = 0,
        ReleaseDelay = 5,
        MinHoldDelay = 5,
        MaxHoldDelay = 5,
        ReleaseDelay = 5,
        HeldDelay = 5

}
local Toggles = {
        Autoplayer = true
}
local start = tick()
local client = game:GetService('Players').LocalPlayer;
local set_identity = (type(syn) == 'table' and syn.set_thread_identity) or setidentity or setthreadcontext
local executor = identifyexecutor and identifyexecutor() or 'Unknown'

local function fail(r) return client:Kick(r) end

local usedCache = shared.__urlcache and next(shared.__urlcache) ~= nil

shared.__urlcache = shared.__urlcache or {}
local function urlLoad(url)
    local success, result

    if shared.__urlcache[url] then
        success, result = true, shared.__urlcache[url]
    else
        success, result = pcall(game.HttpGet, game, url)
    end

    if (not success) then
        return fail(string.format('[PLUTONIUM ERROR]: Failed to GET url %q for reason: %q', url, tostring(result)))
    end

    local fn, err = loadstring(result)
    if (type(fn) ~= 'function') then
        return fail(string.format('[PLUTONIUM ERROR]: Failed to loadstring url %q for reason: %q', url, tostring(err)))
    end

    local results = { pcall(fn) }
    if (not results[1]) then
        return fail(string.format('[PLUTONIUM ERROR]: Failed to initialize url %q for reason: %q', url, tostring(results[2])))
    end

    shared.__urlcache[url] = result
    return unpack(results, 2)
end

-- attempt to block imcompatible exploits
-- rewrote because old checks literally did not work
if type(set_identity) ~= 'function' then return fail('[PLUTONIUM ERROR]: Unsupported exploit (missing "set_thread_identity")') end
if type(getgc) ~= 'function' then   return fail('[PLUTONIUM ERROR]: Unsupported exploit (misssing "getgc")') end

local getinfo = debug.getinfo or getinfo;
local getupvalue = debug.getupvalue or getupvalue;
local getupvalues = debug.getupvalues or getupvalues;
local setupvalue = debug.setupvalue or setupvalue;

if type(setupvalue) ~= 'function' then return fail('[PLUTONIUM ERROR]: Unsupported exploit (misssing "debug.setupvalue")') end
if type(getupvalue) ~= 'function' then return fail('[PLUTONIUM ERROR]: Unsupported exploit (misssing "debug.getupvalue")') end
if type(getupvalues) ~= 'function' then return fail('[PLUTONIUM ERROR]: Unsupported exploit (missing "debug.getupvalues")') end

if type(getinfo) ~= 'function' then
    local debug_info = debug.info;
    if type(debug_info) ~= 'function' then
        if type(getrenv) ~= 'function' then return fail('[PLUTONIUM ERROR]: Unsupported exploit (missing "getrenv")') end
        debug_info = getrenv().debug.info
    end
    getinfo = function(f)
        assert(type(f) == 'function', string.format('Invalid argument #1 to debug.getinfo (expected %s got %s', 'function', type(f)))
        local results = { debug.info(f, 'slnfa') }
        local _, upvalues = pcall(getupvalues, f)
        if type(upvalues) ~= 'table' then
            upvalues = {}
        end
        local nups = 0
        for k in next, upvalues do
            nups = nups + 1
        end
        -- winning code
        return {
            source      = '@' .. results[1],
            short_src   = results[1],
            what        = results[1] == '[C]' and 'C' or 'Lua',
            currentline = results[2],
            name        = results[3],
            func        = results[4],
            numparams   = results[5],
            is_vararg   = results[6], -- 'a' argument returns 2 values :)
            nups        = nups,     
        }
    end
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
loadstring(game:HttpGet("https://pastebin.com/raw/eZ6TwVZM"))()

local httpService = game:GetService('HttpService')

local framework, scrollHandler, network
local counter = 0

while true do
    for _, obj in next, getgc(true) do
        if type(obj) == 'table' then 
            if rawget(obj, 'GameUI') then
                framework = obj;
            elseif type(rawget(obj, 'Server')) == 'table' then
                network = obj;     
            end
        end

        if network and framework then break end
    end

    for _, module in next, getloadedmodules() do
        if module.Name == 'ScrollHandler' then
            scrollHandler = module;
            break;
        end
    end 

    if (type(framework) == 'table' and typeof(scrollHandler) == 'Instance' and type(network) == 'table') then
        break
    end

    counter = counter + 1
    if counter > 6 then
        fail(string.format('[PLUTONIUM ERROR]: Failed to load game dependencies. Details: %s, %s, %s', type(framework), typeof(scrollHandler), type(network)))
    end
    wait(1)
end

local runService = game:GetService('RunService')
local userInputService = game:GetService('UserInputService')
local virtualInputManager = game:GetService('VirtualInputManager')

local random = Random.new()

local task = task or getrenv().task;
local fastWait, fastSpawn = task.wait, task.spawn;

local fireSignal, rollChance do
    function fireSignal(target, signal, ...)
        set_identity(2)
        local didFire = false
        for _, signal in next, getconnections(signal) do
            if type(signal.Function) == 'function' and islclosure(signal.Function) then
                local scr = rawget(getfenv(signal.Function), 'script')
                if scr == target then
                    didFire = true
                    pcall(signal.Function, ...)
                end
            end
        end
        set_identity(7)
    end

local SickBind = ""
local GoodBind = ""
local OkayBind = ""
local BadBind = ""
    function rollChance()
        if Style == 'Manual' then
            if (SickBind:GetState()) then return 'Sick' end
            if (GoodBind:GetState()) then return 'Good' end
            if (OkayBind:GetState()) then return 'Ok' end
            if (BadBind:GetState()) then return 'Bad' end
            return 'Sick'
        end

        local chances = {
            { 'Sick', Settings.SickChance},
            { 'Good', Settings.GoodChance},
            { 'Ok', Settings.OkChance},
            { 'Bad', Settings.BadChance},
            { 'Miss' , Settings.MissChance},
        }

        table.sort(chances, function(a, b)
            return a[2] > b[2]
        end)

        local sum = 0;
        for i = 1, #chances do
            sum += chances[i][2]
        end

        if sum == 0 then
            return chances[random:NextInteger(1, #chances)][1]
        end

        local initialWeight = random:NextInteger(0, sum)
        local weight = 0;

        for i = 1, #chances do
            weight = weight + chances[i][2]

            if weight > initialWeight then
                return chances[i][1]
            end
        end

        return 'Sick'
    end
end

-- autoplayer
local chanceValues do
    chanceValues = { 
        Sick = 96,
        Good = 92,
        Ok = 87,
        Bad = 75,
    }

    local keyCodeMap = {}
    for _, enum in next, Enum.KeyCode:GetEnumItems() do
        keyCodeMap[enum.Value] = enum
    end

    if shared._unload then
        pcall(shared._unload)
    end

    function shared._unload()
        if shared._id then
            pcall(runService.UnbindFromRenderStep, runService, shared._id)
        end

        UI:Unload()

        for i = 1, #shared.threads do
            coroutine.close(shared.threads[i])
        end

        for i = 1, #shared.callbacks do
            task.spawn(shared.callbacks[i])
        end
    end

    shared.threads = {}
    shared.callbacks = {}

    shared._id = httpService:GenerateGUID(false)

    local function pressKey(keyCode, state)
        if Settings.Method == 'Virtual Input' then
            virtualInputManager:SendKeyEvent(state, keyCode, false, nil)
        else
            fireSignal(scrollHandler, userInputService[state and 'InputBegan' or 'InputEnded'], { KeyCode = keyCode, UserInputType = Enum.UserInputType.Keyboard }, false)
        end
    end

    local rng = Random.new()
    runService:BindToRenderStep(shared._id, 1, function()
        
        if (not Toggles.Autoplayer) then 
            return 
        end

        local currentlyPlaying = framework.SongPlayer.CurrentlyPlaying

        if typeof(currentlyPlaying) ~= 'Instance' or not currentlyPlaying:IsA('Sound') then 
            return 
        end

        local arrows = framework.UI:GetNotes()
        local count = framework.SongPlayer:GetKeyCount()
        local mode = count .. 'Key'

        local arrowData = framework.ArrowData[mode].Arrows
        for i, arrow in next, arrows do
            -- todo: switch to this (https://i.imgur.com/pEVe6Tx.png)
            local ignoredNoteTypes = { Death = true, Mechanic = true, Poison = true }

            if type(arrow.NoteDataConfigs) == 'table' then 
                if ignoredNoteTypes[arrow.NoteDataConfigs.Type] then 
                    continue
                end
            end

            if (arrow.Side == framework.UI.CurrentSide) and (not arrow.Marked) and currentlyPlaying.TimePosition > 0 then
                local position = (arrow.Data.Position % count) .. '' 

                local hitboxOffset = 0 
                do
                    local settings = framework.Settings;
                    local offset = type(settings) == 'table' and settings.HitboxOffset;
                    local value = type(offset) == 'table' and offset.Value;

                    if type(value) == 'number' then
                        hitboxOffset = value;
                    end

                    hitboxOffset = hitboxOffset / 1000
                end

                local songTime = framework.SongPlayer.CurrentTime 
                do
                    local configs = framework.SongPlayer.CurrentSongConfigs
                    local playbackSpeed = type(configs) == 'table' and configs.PlaybackSpeed

                    if type(playbackSpeed) ~= 'number' then
                        playbackSpeed = 1
                    end

                    songTime = songTime /  playbackSpeed
                end

                local noteTime = math.clamp((1 - math.abs(arrow.Data.Time - (songTime + hitboxOffset))) * 100, 0, 100)

                local result = rollChance()
                arrow._hitChance = arrow._hitChance or result;

                local hitChance = (Style == 'Manual' and result or arrow._hitChance)
                if hitChance ~= "Miss" and noteTime >= chanceValues[arrow._hitChance] then
                    fastSpawn(function()
                        arrow.Marked = true;
                        local keyCode = keyCodeMap[arrowData[position].Keybinds.Keyboard[1]]

                        pressKey(keyCode, true)

                        local arrowLength = arrow.Data.Length or 0
                        local isHeld = arrowLength > 0

                        local delayMode = Settings.ReleaseDelay

                        local minDelay = isHeld and Settings.MinHoldDelay or Settings.MinHoldDelay;
                        
                        local maxDelay = isHeld and Settings.MaxHoldDelay or Settings.MaxHoldDelay;
                        
                        local noteDelay = isHeld and Settings.HeldDelay or Settings.ReleaseDelay
                        local delayMode = 'Random'
                        local delay = delayMode == 'Random' and rng:NextNumber(minDelay, maxDelay) or noteDelay
                        task.wait(arrowLength + (delay / 1000))

                        pressKey(keyCode, false)
                        arrow.Marked = nil;
                    end)
                end
            end
        end
    end)
end

local ActivateUnlockables do
    local loadStyle = nil
    local function loadStyleProxy(...)

        local upvalues = getupvalues(loadStyle)
        for i, upvalue in next, upvalues do
            if type(upvalue) == 'table' and rawget(upvalue, 'Style') then
                rawset(upvalue, 'Style', nil);
                setupvalue(loadStyle, i, upvalue)
            end
        end

        return loadStyle(...)
    end

    local function applyLoadStyleProxy(...)
        local gc = getgc()
        for i = 1, #gc do
            local obj = gc[i]
            if type(obj) == 'function' then

                local upvalues = getupvalues(obj)
                for i, upv in next, upvalues do
                    if type(upv) == 'function' and getinfo(upv).name == 'LoadStyle' then

                        local function isGameFunction(fn)
                            return getinfo(fn).source:match('%.ArrowSelector%.Customize$')
                        end

                        if isGameFunction(obj) and isGameFunction(upv) then
                            loadStyle = loadStyle or upv
                            setupvalue(obj, i, loadStyleProxy)

                            table.insert(shared.callbacks, function()
                                assert(pcall(setupvalue, obj, i, loadStyle))
                            end)
                        end
                    end
                end
            end
        end
    end

    local success, error = pcall(applyLoadStyleProxy)
    if not success then
        return fail(string.format('[PLUTONIUM ERROR]: Failed to hook LoadStyle function. Error(%q)\nExecutor(%q)\n', error, executor))
    end

    function ActivateUnlockables()
        local idx = table.find(framework.SongsWhitelist, client.UserId)
        if idx then return end

        table.insert(framework.SongsWhitelist, client.UserId)
    end
end
