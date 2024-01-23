-- $ARGS|Channel (1)|Fluid Number (1)|Fluid Name (None)|$ARGS


-- Libraries
local setup = require("/lua/lib/setupUtils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")

-- Args
local args = { ... }
local channel = tonumber(args[1]) or 1
local fluidNum = tonumber(args[2]) or 1
local fluidName = utils.urlDecode(args[3] or "None")


-- Peripherals
local wrappedPers = setup.getPers({
    "monitor",
    "modem",
    "redrouter_1",
    "redrouter_2"
})

local monitor = setup.setupMonitor(
    wrappedPers.monitor[1], 0.5
)
local modem = wrappedPers.modem[1]

-- Setup
local fluids = {}
local moving = false
local direction = 0

local stateData = stateHandler.getState("fluid")
local defaultData = 1
local currentFluidIndex = stateData or defaultData

-- Windows
local winHeader = setup.setupWindow(
    monitor, 1, 1, monitor.x, 6
)
local winFooter = setup.setupWindow(
    monitor, 1, (monitor.y - 3), monitor.x, 4
)
local winMain = setup.setupWindow(
    monitor, 1, 7, monitor.x, (monitor.y - (6 + 4)) 
)


-- Main

function start()
    print("# Program Started")
    
    local deviceData = {
        fluidNum = fluidNum,
        fluidName = fluidName
    }

    fluids = { deviceData }

    local setFluidArray = {
        fluidNum = {1,2,3,4,5,6},
        fluidName = {"None","Lava","Water","Oil","Redstone Acid","Slime"},
        table.sort(fluids,
            function(a, b) return a.fluidNum > b.fluidNum end
        )
        drawHeader()
        drawFooter()
        drawMain()
    }
    fluids = { setFluidArray }
    parallel.waitForAny(joinOrCreate, await)
end

-- FluidController

function await()
    while(true) do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isTouch = (event == "monitor_touch")
        local isModemMessage = (event == "modem_message")
        
        if(isTouch) then
            local x = p2
            local y = p3 - winHeader.y
            
            local fluidIndex = y - 4
            local fluid = fluids[fluidIndex]
            if(fluid and (fluidIndex) ~= currentFluidIndex) then
                moveTo(fluidIndex)
                break
            end
        end
    end
end

function moveTo(fluidIndex)
    local fluid = fluids[fluidIndex]
    direction = currentFluidIndex - fluidIndex 
    currentFluidIndex = fluidIndex
    moving = true
    updateState()

    sendSignal(fluid.fluidNum)
    
    drawMain()
    
    sendSignal(fluid.fluidNum)

    await()
end

function sendSignal(targetFluidNum)
    if(fluid.fluidNum = 1) then
        redrouter_1.setOutput(top, on)
    else if(fluid.fluidNum = 2) then
        redrouter_1.setOutput(left, on)
    else if(fluid.fluidNum = 3) then
        redrouter_1.setOutput(bottom, on)
    else if(fluid.fluidNum = 4) then
        redrouter_1.setOutput(right, on)
    else if(fluid.fluidNum = 5) then
        redrouter_1.setOutput(back, on)
    else if(fluid.fluidNum = 6) then
        redrouter_2.setOutput(right, on)
    end
end

function updateState()
    stateHandler.updateState("elevator", currentFluidIndex)
end

function drawHeader()
    winHeader.bg = colors.orange
    winHeader.setBackgroundColor(winHeader.bg)
    
    drawBox(winHeader,
        1, 1, winHeader.x, winHeader.y,
        true
    )
    drawBox(winHeader,
        1, winHeader.y, winHeader.x, winHeader.y,
        true, colors.gray
    )
    
    write(winHeader, "Fluid Controller", 0, 2, "center")
    write(winHeader, "Current Fluid: " .. fluidName, 0, 4, "center")
end

function drawFooter()
    winFooter.bg = colors.orange
    winFooter.setBackgroundColor(winFooter.bg)
    
    drawBox(winFooter,
        1, 1, winFooter.x, winFooter.y,
        true
    )
    drawBox(winFooter,
        1, 1, winFooter.x, 1,
        true, colors.gray
    )
    
    write(winFooter, "Select a fluid", 2, 3, "left")
end

function drawMain()
    winMain.bg = colors.brown
    winMain.setBackgroundColor(winMain.bg)
    
    drawBox(winMain,
        1, 1, winMain.x, winMain.y,
        true
    )
    
    if(moving) then
        parallel.waitForAny(
            drawMoving, awaitFinish,
            function() sleep(120) end
        )
        moving = false
        drawMain()
    else
        drawFluids()
    end
end

function drawMoving()
    local i = 1
    local max = winMain.y - 4
    while(true) do
        i = i + 1
        if(i > max) then i = 1 end
        
        local dirStr = "\\/"
        if(direction > 0) then
            dirStr = "/\\"
        end
        
        winMain.clear()
        local fluid = fluids[currentFluidIndex]
        
        write(winMain,
            "Dispensing: " .. fluid.fluidName,
            0, 2, "center"
        )
        
        for ii = 1, 5, 1 do
            local y = i + ii - 1
            if(y > max) then y = y % max end
            if(direction > 0) then
                y = (y - max - 1) * -1
            end
            
            write(winMain,
                dirStr,
                0, (y + 3), "center"
            )
        end
        
        os.sleep(0.1)
    end
end

function awaitFinish()
    sleep(1)
    while(true) do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isRedstone = (event == "redstone")
        
    end
end
    
function drawFluids()
    if(currentFluidIndex > #fluids) then 
        currentFluidIndex = 1
    end
    write(winMain,
        "Fluid: " .. fluids[currentFluidIndex].fluidName,
        2, 2, "right"
    )
    write(winMain,
        "# Fluids",
        2, 2, "left"
    )
    
    for i, fluid in ipairs(fluids) do
        local y = 4 + i
        if(i == currentFluidIndex) then
            drawBox(winMain,
                1, y, winMain.x, y,
                true, colors.orange
            )
            winMain.setBackgroundColor(colors.brown)
        end
        write(winMain,
            " > " .. fluid.fluidName .. " ",
            2, y, "left"
        )
        winMain.setBackgroundColor(winMain.bg)
    end
end

setup.utilsWrapper(start)

