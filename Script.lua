-- AzyroX Hub
-- Paste into your executor

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local CoreGui      = game:GetService("CoreGui")
local LocalPlayer  = Players.LocalPlayer
local Camera       = workspace.CurrentCamera

-- ============================================================
-- AIMBOT STATE
-- ============================================================
local SilentAimSettings = { Enabled=false, TeamCheck=true, HitPart="Head" }
local _origScreenPointToRay=nil; local _origViewportPointToRay=nil; local _saHooked=false

local function getSilentTarget()
    local best,bestDist=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        repeat
        if plr==LocalPlayer then break end
        if SilentAimSettings.TeamCheck and plr.Team==LocalPlayer.Team then break end
        local char=plr.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health<=0 then break end
        local part=char:FindFirstChild(SilentAimSettings.HitPart) or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
        if not part then break end
        local _,onScreen=Camera:WorldToViewportPoint(part.Position)
        if not onScreen then break end
        local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dist=myRoot and (part.Position-myRoot.Position).Magnitude or math.huge
        if dist<bestDist then bestDist=dist; best=part end
        until true
    end
    return best
end

local function hookSilentAim()
    if _saHooked then return end; _saHooked=true
    _origScreenPointToRay=Camera.ScreenPointToRay
    _origViewportPointToRay=Camera.ViewportPointToRay
    Camera.ScreenPointToRay=function(self,x,y,depth)
        if SilentAimSettings.Enabled then
            local t=getSilentTarget()
            if t then local o=Camera.CFrame.Position; local d=depth or 1; return Ray.new(o,(t.Position-o).Unit*d) end
        end
        return _origScreenPointToRay(self,x,y,depth)
    end
    Camera.ViewportPointToRay=function(self,x,y,depth)
        if SilentAimSettings.Enabled then
            local t=getSilentTarget()
            if t then local o=Camera.CFrame.Position; local d=depth or 1; return Ray.new(o,(t.Position-o).Unit*d) end
        end
        return _origViewportPointToRay(self,x,y,depth)
    end
end
local function unhookSilentAim()
    if not _saHooked then return end
    if _origScreenPointToRay then Camera.ScreenPointToRay=_origScreenPointToRay end
    if _origViewportPointToRay then Camera.ViewportPointToRay=_origViewportPointToRay end
    _saHooked=false
end

local AimbotSettings = { Enabled=false, TeamCheck=false, FOV=120, Smoothness=0.35, Target="Head", ShowFOV=false, ShowDot=true, FOVColor=Color3.fromRGB(200,40,40), FOVFilled=false, FOVFillTransp=0.7 }
local TargetPartMap = { ["Head"]="Head", ["Body"]="HumanoidRootPart", ["Legs"]="LowerTorso" }

local function makeDrawing(class,props)
    local ok,obj=pcall(function() return Drawing.new(class) end)
    if not ok or not obj then
        local stub={}; setmetatable(stub,{__index=function() return false end,__newindex=function() end}); stub.Remove=function() end; return stub
    end
    for k,v in pairs(props) do pcall(function() obj[k]=v end) end; return obj
end

local FOVRing=makeDrawing("Circle",{Thickness=0,Color=Color3.new(1,1,1),Filled=true,Visible=false,NumSides=64})
local FOVCircle=makeDrawing("Circle",{Thickness=0,Color=Color3.fromRGB(200,40,40),Filled=true,Visible=false,NumSides=64})
local FOVOutline=makeDrawing("Circle",{Thickness=1,Color=Color3.new(1,1,1),Filled=false,Visible=false,NumSides=64})
local DotGlow2=makeDrawing("Circle",{Radius=10,Thickness=1,Color=Color3.fromRGB(255,60,60),Filled=true,Visible=false,NumSides=32,Transparency=0.82})
local DotGlow1=makeDrawing("Circle",{Radius=6,Thickness=1,Color=Color3.fromRGB(255,80,80),Filled=true,Visible=false,NumSides=32,Transparency=0.55})
local TargetDot=makeDrawing("Circle",{Radius=3,Thickness=1,Color=Color3.fromRGB(255,255,255),Filled=true,Visible=false,NumSides=32,Transparency=0})

local CrosshairSettings = { Enabled=false, Style="Cross", Color=Color3.fromRGB(255,255,255), Size=10, Gap=4, Thickness=1, Rotation=0, Spin=false, SpinSpeed=90 }
local CH_Top_O=makeDrawing("Line",{Thickness=3,Color=Color3.new(0,0.4,1),Visible=false})
local CH_Bot_O=makeDrawing("Line",{Thickness=3,Color=Color3.new(0,0.4,1),Visible=false})
local CH_Left_O=makeDrawing("Line",{Thickness=3,Color=Color3.new(0,0.4,1),Visible=false})
local CH_Right_O=makeDrawing("Line",{Thickness=3,Color=Color3.new(0,0.4,1),Visible=false})
local CH_Top=makeDrawing("Line",{Thickness=1,Color=Color3.new(1,1,1),Visible=false})
local CH_Bot=makeDrawing("Line",{Thickness=1,Color=Color3.new(1,1,1),Visible=false})
local CH_Left=makeDrawing("Line",{Thickness=1,Color=Color3.new(1,1,1),Visible=false})
local CH_Right=makeDrawing("Line",{Thickness=1,Color=Color3.new(1,1,1),Visible=false})
local CH_Dot=makeDrawing("Circle",{Radius=2,Filled=true,Color=Color3.new(1,1,1),Visible=false,NumSides=32})
local CH_Circle=makeDrawing("Circle",{Radius=10,Filled=false,Thickness=1,Color=Color3.new(1,1,1),Visible=false,NumSides=64})
local chLastTime=0

local SoundSettings = { Enabled=false, SoundId="rbxassetid://4612375452", Volume=0.5 }
local SOUND_PRESETS = { ["Vine Boom"]="rbxassetid://4612375452", ["Among Us"]="rbxassetid://5153845556", ["Bruh"]="rbxassetid://782433158", ["Oof"]="rbxassetid://6894663660", ["Headshot"]="rbxassetid://4634188302", ["Rizz"]="rbxassetid://16495165776", ["Skibidi"]="rbxassetid://16480549740", ["Custom ID"]="custom" }
local _hitSoundObj=nil
local function getHitSound()
    if _hitSoundObj and _hitSoundObj.Parent then return _hitSoundObj end
    local s=Instance.new("Sound"); s.Name="AzyroXHitSound"; s.Volume=SoundSettings.Volume; s.RollOffMaxDistance=10000; s.Parent=game:GetService("SoundService"); _hitSoundObj=s; return s
end
local function playHitSound()
    if not SoundSettings.Enabled then return end
    local s=getHitSound(); s.SoundId=SoundSettings.SoundId; s.Volume=SoundSettings.Volume; s:Stop(); s:Play()
end

local _hitConnections={}
local function hookPlayer(plr)
    if _hitConnections[plr] then return end
    local function tryHook(char)
        if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not hum then
            char.ChildAdded:Connect(function(child)
                if child:IsA("Humanoid") then
                    child.HealthChanged:Connect(function(newHP)
                        if not SoundSettings.Enabled then return end; if newHP<child.Health then return end; playHitSound()
                    end)
                end
            end); return
        end
        local prevHP=hum.Health
        local conn=hum.HealthChanged:Connect(function(newHP)
            if not SoundSettings.Enabled then return end; if newHP<prevHP then playHitSound() end; prevHP=newHP
        end); _hitConnections[plr]=conn
    end
    tryHook(plr.Character)
    plr.CharacterAdded:Connect(function(char)
        if _hitConnections[plr] then _hitConnections[plr]:Disconnect(); _hitConnections[plr]=nil end
        task.wait(0.5); tryHook(char)
    end)
end
local _hitDetectConn=nil
local function startHitDetect()
    for _,plr in ipairs(Players:GetPlayers()) do repeat if plr==LocalPlayer then break end; hookPlayer(plr) until true end
    _hitDetectConn=Players.PlayerAdded:Connect(function(plr) hookPlayer(plr) end)
end
local function stopHitDetect()
    for plr,conn in pairs(_hitConnections) do pcall(function() conn:Disconnect() end) end
    _hitConnections={}; if _hitDetectConn then _hitDetectConn:Disconnect(); _hitDetectConn=nil end
end

local function updateCrosshair()
    if CrosshairSettings.Spin and CrosshairSettings.Enabled then
        local now=tick(); local dt=now-chLastTime
        CrosshairSettings.Rotation=(CrosshairSettings.Rotation+CrosshairSettings.SpinSpeed*dt)%360
    end
    chLastTime=tick()
    local vp=Camera.ViewportSize; local cx=vp.X/2; local cy=vp.Y/2
    local s=CrosshairSettings.Size; local g=CrosshairSettings.Gap; local col=CrosshairSettings.Color
    local thick=CrosshairSettings.Thickness; local style=CrosshairSettings.Style
    local on=CrosshairSettings.Enabled; local rot=math.rad(CrosshairSettings.Rotation)
    CH_Top.Visible=false; CH_Bot.Visible=false; CH_Left.Visible=false; CH_Right.Visible=false
    CH_Top_O.Visible=false; CH_Bot_O.Visible=false; CH_Left_O.Visible=false; CH_Right_O.Visible=false
    CH_Dot.Visible=false; CH_Circle.Visible=false
    if not on then return end
    if style=="Cross" or style=="Big E" then
        local function rotPt(dx,dy)
            return Vector2.new(cx+dx*math.cos(rot)-dy*math.sin(rot), cy+dx*math.sin(rot)+dy*math.cos(rot))
        end
        CH_Top.From=rotPt(0,-(g+s)); CH_Top.To=rotPt(0,-g)
        CH_Bot.From=rotPt(0,g); CH_Bot.To=rotPt(0,g+s)
        CH_Left.From=rotPt(-(g+s),0); CH_Left.To=rotPt(-g,0)
        CH_Right.From=rotPt(g,0); CH_Right.To=rotPt(g+s,0)
        if style=="Big E" then
            for _,ln in ipairs({CH_Top_O,CH_Bot_O,CH_Left_O,CH_Right_O}) do ln.Color=Color3.fromRGB(0,100,255); ln.Thickness=thick+2; ln.Visible=true end
            CH_Top_O.From=CH_Top.From; CH_Top_O.To=CH_Top.To; CH_Bot_O.From=CH_Bot.From; CH_Bot_O.To=CH_Bot.To
            CH_Left_O.From=CH_Left.From; CH_Left_O.To=CH_Left.To; CH_Right_O.From=CH_Right.From; CH_Right_O.To=CH_Right.To
            for _,ln in ipairs({CH_Top,CH_Bot,CH_Left,CH_Right}) do ln.Color=Color3.new(1,1,1); ln.Thickness=thick; ln.Visible=true end
        else
            for _,ln in ipairs({CH_Top,CH_Bot,CH_Left,CH_Right}) do ln.Color=col; ln.Thickness=thick; ln.Visible=true end
        end
    elseif style=="Dot" then
        CH_Dot.Position=Vector2.new(cx,cy); CH_Dot.Radius=math.max(thick,2); CH_Dot.Color=col; CH_Dot.Visible=true
    elseif style=="Circle" then
        CH_Circle.Position=Vector2.new(cx,cy); CH_Circle.Radius=s; CH_Circle.Thickness=thick; CH_Circle.Color=col; CH_Circle.Visible=true
    end
end

local function getTargetPart(char)
    local name=TargetPartMap[AimbotSettings.Target] or "Head"
    return char:FindFirstChild(name) or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end
local function getClosestPlayer()
    local vp=Camera.ViewportSize; local center=Vector2.new(vp.X/2,vp.Y/2)
    local best=nil; local bestDist=AimbotSettings.FOV
    for _,plr in ipairs(Players:GetPlayers()) do
        repeat
        if plr==LocalPlayer then break end
        if AimbotSettings.TeamCheck and plr.Team==LocalPlayer.Team then break end
        local char=plr.Character; if not char then break end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then break end
        local part=getTargetPart(char); if not part then break end
        local sp,onScreen=Camera:WorldToViewportPoint(part.Position); if not onScreen then break end
        local dist=(Vector2.new(sp.X,sp.Y)-center).Magnitude
        if dist<bestDist then bestDist=dist; best=part end
        until true
    end
    return best
end

RunService.RenderStepped:Connect(function()
    local vp=Camera.ViewportSize; local center=Vector2.new(vp.X/2,vp.Y/2)
    if AimbotSettings.ShowFOV and AimbotSettings.Enabled then
        local r=AimbotSettings.FOV; local col=AimbotSettings.FOVColor
        FOVCircle.Position=center; FOVCircle.Radius=r-8; FOVCircle.Color=col; FOVCircle.Filled=true
        FOVCircle.Transparency=AimbotSettings.FOVFilled and AimbotSettings.FOVFillTransp or 1; FOVCircle.Visible=AimbotSettings.FOVFilled
        FOVOutline.Position=center; FOVOutline.Radius=r; FOVOutline.Color=Color3.new(1,1,1)
        FOVOutline.Filled=false; FOVOutline.Transparency=0; FOVOutline.Thickness=8; FOVOutline.Visible=true
        FOVRing.Visible=false
    else FOVRing.Visible=false; FOVCircle.Visible=false; FOVOutline.Visible=false end

    local dotTarget=nil
    if AimbotSettings.Enabled and AimbotSettings.ShowDot then dotTarget=getClosestPlayer() end
    if dotTarget then
        local sp,onScreen=Camera:WorldToViewportPoint(dotTarget.Position)
        if onScreen then
            local pos=Vector2.new(sp.X,sp.Y)
            DotGlow2.Position=pos; DotGlow2.Visible=true
            DotGlow1.Position=pos; DotGlow1.Visible=true
            TargetDot.Position=pos; TargetDot.Visible=true
        else DotGlow2.Visible=false; DotGlow1.Visible=false; TargetDot.Visible=false end
    else DotGlow2.Visible=false; DotGlow1.Visible=false; TargetDot.Visible=false end

    if AimbotSettings.Enabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target=getClosestPlayer()
        if target then
            local sp,onScreen=Camera:WorldToViewportPoint(target.Position)
            if onScreen then
                local cx,cy=vp.X/2,vp.Y/2; local dx=sp.X-cx; local dy=sp.Y-cy
                local s=math.clamp(AimbotSettings.Smoothness,0.05,1); pcall(mousemoverel,dx*s,dy*s)
            end
        end
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local ESPSettings = { NameESP=false, BoxESP=false, HealthBar=false, Tracers=false, TeamCheck=false, BoxColor=Color3.fromRGB(200,40,40), TracerColor=Color3.fromRGB(200,40,40) }
local ESPObjects={}
local function newDraw(dtype,props)
    local ok,d=pcall(function() return Drawing.new(dtype) end)
    if not ok or not d then local stub={}; setmetatable(stub,{__index=function() return false end,__newindex=function() end}); stub.Remove=function() end; return stub end
    for k,v in pairs(props) do pcall(function() d[k]=v end) end; return d
end
local function removeESP(plr)
    if ESPObjects[plr] then for _,d in pairs(ESPObjects[plr]) do pcall(function() d:Remove() end) end; ESPObjects[plr]=nil end
end
local function createESP(plr)
    if plr==LocalPlayer then return end; removeESP(plr)
    ESPObjects[plr]={
        Name=newDraw("Text",{Text=plr.Name,Size=14,Font=2,Color=Color3.new(1,1,1),Outline=true,OutlineColor=Color3.new(0,0,0),Center=true,Visible=false}),
        BoxTop=newDraw("Line",{Thickness=1,Color=ESPSettings.BoxColor,Visible=false}),
        BoxBottom=newDraw("Line",{Thickness=1,Color=ESPSettings.BoxColor,Visible=false}),
        BoxLeft=newDraw("Line",{Thickness=1,Color=ESPSettings.BoxColor,Visible=false}),
        BoxRight=newDraw("Line",{Thickness=1,Color=ESPSettings.BoxColor,Visible=false}),
        HealthBG=newDraw("Line",{Thickness=4,Color=Color3.fromRGB(20,20,20),Visible=false}),
        HealthFill=newDraw("Line",{Thickness=4,Color=Color3.fromRGB(80,200,80),Visible=false}),
        Tracer=newDraw("Line",{Thickness=1,Color=ESPSettings.TracerColor,Visible=false}),
    }
end
for _,p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP); Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    for plr,o in pairs(ESPObjects) do
        repeat
        for _,d in pairs(o) do d.Visible=false end
        if plr==LocalPlayer then break end
        if not plr.Character then break end
        local char=plr.Character; local root=char:FindFirstChild("HumanoidRootPart"); local head=char:FindFirstChild("Head"); local hum=char:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum then break end; if hum.Health<=0 then break end
        if ESPSettings.TeamCheck and plr.Team==LocalPlayer.Team then break end
        local rp,rv=Camera:WorldToViewportPoint(root.Position); if not rv then break end
        local hp=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,.5,0))
        local fp=Camera:WorldToViewportPoint(root.Position-Vector3.new(0,3,0))
        local sh=Vector2.new(hp.X,hp.Y); local sf=Vector2.new(fp.X,fp.Y); local sr=Vector2.new(rp.X,rp.Y)
        local ht=math.abs(sh.Y-sf.Y); local wd=ht*0.55
        local tl=Vector2.new(sh.X-wd,sh.Y); local tr=Vector2.new(sh.X+wd,sh.Y)
        local bl=Vector2.new(sh.X-wd,sf.Y); local br=Vector2.new(sh.X+wd,sf.Y)
        if ESPSettings.NameESP then o.Name.Position=Vector2.new(sh.X,sh.Y-16); o.Name.Text=plr.Name; o.Name.Visible=true end
        if ESPSettings.BoxESP then
            o.BoxTop.From=tl;o.BoxTop.To=tr;o.BoxTop.Color=ESPSettings.BoxColor;o.BoxTop.Visible=true
            o.BoxBottom.From=bl;o.BoxBottom.To=br;o.BoxBottom.Color=ESPSettings.BoxColor;o.BoxBottom.Visible=true
            o.BoxLeft.From=tl;o.BoxLeft.To=bl;o.BoxLeft.Color=ESPSettings.BoxColor;o.BoxLeft.Visible=true
            o.BoxRight.From=tr;o.BoxRight.To=br;o.BoxRight.Color=ESPSettings.BoxColor;o.BoxRight.Visible=true
        end
        if ESPSettings.HealthBar then
            local pct=math.clamp(hum.Health/hum.MaxHealth,0,1); local bx=tl.X-6; local fy=tl.Y+(bl.Y-tl.Y)*(1-pct)
            o.HealthBG.From=Vector2.new(bx,tl.Y);o.HealthBG.To=Vector2.new(bx,bl.Y);o.HealthBG.Visible=true
            o.HealthFill.From=Vector2.new(bx,fy);o.HealthFill.To=Vector2.new(bx,bl.Y)
            o.HealthFill.Color=Color3.fromRGB(math.floor(255*(1-pct)),math.floor(255*pct),50); o.HealthFill.Visible=true
        end
        if ESPSettings.Tracers then
            local vp=Camera.ViewportSize; o.Tracer.From=Vector2.new(vp.X/2,vp.Y); o.Tracer.To=sr; o.Tracer.Color=ESPSettings.TracerColor; o.Tracer.Visible=true
        end
        until true
    end
end)

-- ============================================================
-- FLY / ORBIT / WALLBANG / SKYFLY / UNDER
-- ============================================================
local FlySettings={Enabled=false,Speed=60}; local flyConn=nil; local flyBV=nil; local flyBG=nil
local function startFly()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid"); if not root or not hum then return end
    hum.PlatformStand=true
    flyBV=Instance.new("BodyVelocity"); flyBV.Velocity=Vector3.zero; flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Parent=root
    flyBG=Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); flyBG.D=50; flyBG.CFrame=root.CFrame; flyBG.Parent=root
    flyConn=RunService.RenderStepped:Connect(function()
        if not FlySettings.Enabled then return end
        local r=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not r or not flyBV or not flyBV.Parent then return end
        local spd=FlySettings.Speed; local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
        flyBV.Velocity=dir.Magnitude>0 and dir.Unit*spd or Vector3.zero; flyBG.CFrame=Camera.CFrame
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect();flyConn=nil end
    if flyBV and flyBV.Parent then flyBV:Destroy();flyBV=nil end
    if flyBG and flyBG.Parent then flyBG:Destroy();flyBG=nil end
    local char=LocalPlayer.Character; if char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end end
end

local OrbitSettings={Enabled=false,Target="",Radius=10,Speed=1.5}; local orbitAngle=0; local orbitConn=nil
local function getOrbitTarget()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Name==OrbitSettings.Target then local c=plr.Character; return c and c:FindFirstChild("HumanoidRootPart") end
    end
    local best,bestDist=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        repeat if plr==LocalPlayer then break end
        local c=plr.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
        if r then local d=(r.Position-(LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.zero)).Magnitude; if d<bestDist then bestDist=d;best=r end end
        until true
    end; return best
end
local function startOrbit()
    if orbitConn then orbitConn:Disconnect() end
    orbitConn=RunService.RenderStepped:Connect(function(dt)
        if not OrbitSettings.Enabled then return end
        local char=LocalPlayer.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local tgt=getOrbitTarget(); if not tgt then return end
        orbitAngle=orbitAngle+OrbitSettings.Speed*dt
        local r=OrbitSettings.Radius
        root.CFrame=CFrame.new(Vector3.new(tgt.Position.X+math.cos(orbitAngle)*r,tgt.Position.Y+3,tgt.Position.Z+math.sin(orbitAngle)*r),tgt.Position)
    end)
end
local function stopOrbit()
    if orbitConn then orbitConn:Disconnect();orbitConn=nil end
    local char=LocalPlayer.Character; if char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end end
end

local VFlySettings={Enabled=false,Speed=80}; local vFlyConn=nil; local vFlyBV=nil; local vFlyBG=nil
local function startVFly()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid"); if not root or not hum then return end
    hum.PlatformStand=true
    vFlyBV=Instance.new("BodyVelocity"); vFlyBV.Velocity=Vector3.zero; vFlyBV.MaxForce=Vector3.new(1e6,1e6,1e6); vFlyBV.Parent=root
    vFlyBG=Instance.new("BodyGyro"); vFlyBG.MaxTorque=Vector3.new(4e5,4e5,4e5); vFlyBG.D=100; vFlyBG.P=1e4; vFlyBG.CFrame=root.CFrame; vFlyBG.Parent=root
    local currentVel=Vector3.zero
    vFlyConn=RunService.Heartbeat:Connect(function(dt)
        if not VFlySettings.Enabled then return end
        local r=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not r or not vFlyBV or not vFlyBV.Parent then return end
        local spd=VFlySettings.Speed; local dir=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
        local targetVel=dir.Magnitude>0 and dir.Unit*spd or Vector3.zero
        currentVel=currentVel:Lerp(targetVel,math.clamp(dt*14,0,1)); vFlyBV.Velocity=currentVel
        if currentVel.Magnitude>1 then vFlyBG.CFrame=CFrame.new(Vector3.zero,currentVel) end
    end)
end
local function stopVFly()
    if vFlyConn then vFlyConn:Disconnect();vFlyConn=nil end
    if vFlyBV and vFlyBV.Parent then vFlyBV:Destroy();vFlyBV=nil end
    if vFlyBG and vFlyBG.Parent then vFlyBG:Destroy();vFlyBG=nil end
    local char=LocalPlayer.Character; if char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end end
end

local SkyFlySettings={Enabled=false,Speed=80,Height=400}
local skyFlyConn=nil; local skyFlyBV=nil; local skyFlyBG=nil; local skyFlyBP=nil
local function startSkyFly()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid"); if not root or not hum then return end
    hum.PlatformStand=true
    for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.LocalTransparencyModifier=1 end) end end
    root.CFrame=CFrame.new(root.Position.X,root.Position.Y+SkyFlySettings.Height,root.Position.Z)
    skyFlyBV=Instance.new("BodyVelocity"); skyFlyBV.Velocity=Vector3.zero; skyFlyBV.MaxForce=Vector3.new(1e5,1e5,1e5); skyFlyBV.Parent=root
    skyFlyBG=Instance.new("BodyGyro"); skyFlyBG.MaxTorque=Vector3.new(1e5,1e5,1e5); skyFlyBG.D=50; skyFlyBG.CFrame=root.CFrame; skyFlyBG.Parent=root
    skyFlyBP=Instance.new("BodyPosition"); skyFlyBP.MaxForce=Vector3.new(0,1e5,0); skyFlyBP.D=500; skyFlyBP.P=10000; skyFlyBP.Position=root.Position; skyFlyBP.Parent=root
    skyFlyConn=RunService.RenderStepped:Connect(function()
        if not SkyFlySettings.Enabled then return end
        local r=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not r or not skyFlyBV or not skyFlyBV.Parent then return end
        local spd=SkyFlySettings.Speed; local dir=Vector3.zero; local camCF=Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-camCF.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+camCF.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir=dir-Vector3.new(0,1,0) end
        if dir.Magnitude>0 then
            skyFlyBV.Velocity=dir.Unit*spd
            if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then skyFlyBP.Position=r.Position end
        else skyFlyBV.Velocity=Vector3.zero; skyFlyBP.Position=Vector3.new(skyFlyBP.Position.X,r.Position.Y,skyFlyBP.Position.Z) end
        skyFlyBG.CFrame=camCF
    end)
end
local function stopSkyFly()
    if skyFlyConn then skyFlyConn:Disconnect();skyFlyConn=nil end
    if skyFlyBV and skyFlyBV.Parent then skyFlyBV:Destroy();skyFlyBV=nil end
    if skyFlyBG and skyFlyBG.Parent then skyFlyBG:Destroy();skyFlyBG=nil end
    if skyFlyBP and skyFlyBP.Parent then skyFlyBP:Destroy();skyFlyBP=nil end
    local char=LocalPlayer.Character
    if char then
        local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end
        for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.LocalTransparencyModifier=0 end) end end
    end
end

local UnderSettings={Enabled=false,Target="",Offset=-4,SafeMode=true,AutoShoot=true,ShootRate=0.1}
local underConn=nil; local underBV=nil; local hiddenParts={}; local underLastPos=nil; local underShootConn=nil; local underShootTimer=0
local function getUnderTarget()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=LocalPlayer and plr.Name==UnderSettings.Target then local c=plr.Character; return c and c:FindFirstChild("HumanoidRootPart") end
    end
    local best,bestDist=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        repeat if plr==LocalPlayer then break end
        local c=plr.Character; local root=c and c:FindFirstChild("HumanoidRootPart")
        if root then local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); local myPos=myRoot and myRoot.Position or Vector3.zero; local d=(root.Position-myPos).Magnitude; if d<bestDist then bestDist=d;best=root end end
        until true
    end; return best
end
local function hideLocalChar() local char=LocalPlayer.Character; if not char then return end; hiddenParts={}; for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then table.insert(hiddenParts,{part=p,orig=p.LocalTransparencyModifier}); p.LocalTransparencyModifier=1 end end end
local function showLocalChar() for _,e in ipairs(hiddenParts) do pcall(function() e.part.LocalTransparencyModifier=e.orig end) end; hiddenParts={} end
local underBP=nil; local underBG2=nil
local function underAnchor(root,pos)
    if not underBP or not underBP.Parent then underBP=Instance.new("BodyPosition"); underBP.MaxForce=Vector3.new(1e5,1e5,1e5); underBP.D=1000; underBP.P=25000; underBP.Parent=root end; underBP.Position=pos
    if not underBG2 or not underBG2.Parent then underBG2=Instance.new("BodyGyro"); underBG2.MaxTorque=Vector3.new(1e5,1e5,1e5); underBG2.P=10000; underBG2.Parent=root end; underBG2.CFrame=CFrame.new(pos)
end
local function underUnanchor() if underBP and underBP.Parent then underBP:Destroy();underBP=nil end; if underBG2 and underBG2.Parent then underBG2:Destroy();underBG2=nil end end
local function startUnder()
    if underConn then underConn:Disconnect() end; hideLocalChar(); underLastPos=nil
    underConn=RunService.Heartbeat:Connect(function(dt)
        if not UnderSettings.Enabled then return end
        local char=LocalPlayer.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid"); if not root or not hum then return end
        hum.PlatformStand=true
        local tgt=getUnderTarget()
        if not tgt then underAnchor(root,root.Position); return end
        local jx=(math.random()-0.5)*0.15; local jz=(math.random()-0.5)*0.15
        local desiredPos=tgt.Position+Vector3.new(jx,UnderSettings.Offset,jz)
        local currentPos=root.Position
        if UnderSettings.SafeMode then local maxDelta=250*dt; local diff=desiredPos-currentPos; if diff.Magnitude>maxDelta then desiredPos=currentPos+diff.Unit*maxDelta end end
        underAnchor(root,desiredPos); root.CFrame=CFrame.new(desiredPos); underLastPos=desiredPos
        local camPos=Camera.CFrame.Position; Camera.CFrame=CFrame.lookAt(camPos,tgt.Position)
    end)
    if underShootConn then underShootConn:Disconnect() end
    underShootConn=RunService.Heartbeat:Connect(function(dt)
        if not UnderSettings.Enabled or not UnderSettings.AutoShoot then return end
        underShootTimer=underShootTimer+dt
        if underShootTimer>=UnderSettings.ShootRate then underShootTimer=0; pcall(mouse1press); pcall(mouse1release) end
    end)
end
local function stopUnder()
    if underConn then underConn:Disconnect();underConn=nil end
    if underShootConn then underShootConn:Disconnect();underShootConn=nil end
    underShootTimer=0
    if underBV and underBV.Parent then underBV:Destroy();underBV=nil end
    underUnanchor(); underLastPos=nil; showLocalChar()
    local char=LocalPlayer.Character; if char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end end
end

local WB2Settings={Enabled=false,Target="",Interval=0.08,VoidDepth=-500}
local wb2Conn=nil; local wb2Hidden={}; local wb2VoidX=0; local wb2VoidZ=0
local function getWB2Target()
    local function isValid(plr)
        if plr==LocalPlayer then return false end
        local myTeam=LocalPlayer.Team; local plrTeam=plr.Team
        if myTeam and plrTeam and myTeam==plrTeam then return false end
        local c=plr.Character; if not c then return false end
        local root=c:FindFirstChild("HumanoidRootPart"); if not root then return false end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return false end
        if hum.Health<=0 then return false end; if hum.Health~=hum.Health then return false end
        if root.Position.Y<-200 then return false end; if not c.Parent then return false end; if c.Parent~=workspace then return false end; return true
    end
    if WB2Settings.Target~="" then
        for _,plr in ipairs(Players:GetPlayers()) do if plr.Name==WB2Settings.Target and isValid(plr) then return plr.Character:FindFirstChild("HumanoidRootPart") end end; return nil
    end
    local best,bestDist=nil,math.huge; local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); local myPos=myRoot and myRoot.Position or Vector3.zero
    for _,plr in ipairs(Players:GetPlayers()) do repeat if not isValid(plr) then break end; local root=plr.Character:FindFirstChild("HumanoidRootPart"); local d=(root.Position-myPos).Magnitude; if d<bestDist then bestDist=d;best=root end until true end; return best
end
local function wb2HideChar() local char=LocalPlayer.Character; if not char then return end; wb2Hidden={}; for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then table.insert(wb2Hidden,{part=p,orig=p.LocalTransparencyModifier}); p.LocalTransparencyModifier=1 end end end
local function wb2ShowChar() for _,e in ipairs(wb2Hidden) do pcall(function() e.part.LocalTransparencyModifier=e.orig end) end; wb2Hidden={} end
local wb2BP=nil; local wb2BG=nil
local function wb2Anchor(root,voidX,voidZ)
    if not wb2BP or not wb2BP.Parent then wb2BP=Instance.new("BodyPosition"); wb2BP.MaxForce=Vector3.new(1e5,1e5,1e5); wb2BP.D=500; wb2BP.P=10000; wb2BP.Parent=root end; wb2BP.Position=Vector3.new(voidX,WB2Settings.VoidDepth,voidZ)
    if not wb2BG or not wb2BG.Parent then wb2BG=Instance.new("BodyGyro"); wb2BG.MaxTorque=Vector3.new(1e5,1e5,1e5); wb2BG.P=10000; wb2BG.Parent=root end; wb2BG.CFrame=CFrame.new(root.Position)
end
local function wb2Unanchor() if wb2BP and wb2BP.Parent then wb2BP:Destroy();wb2BP=nil end; if wb2BG and wb2BG.Parent then wb2BG:Destroy();wb2BG=nil end end
local function startWB2()
    if wb2Conn then wb2Conn:Disconnect() end; wb2HideChar()
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid"); if not root or not hum then return end
    hum.PlatformStand=true; wb2VoidX=root.Position.X; wb2VoidZ=root.Position.Z
    root.CFrame=CFrame.new(wb2VoidX,WB2Settings.VoidDepth,wb2VoidZ); wb2Anchor(root,wb2VoidX,wb2VoidZ)
    local timer=0; local stayTimer=0; local onTarget=false; local lastTgt=nil; local STAY_TIME=0.325
    wb2Conn=RunService.Heartbeat:Connect(function(dt)
        if not WB2Settings.Enabled then return end
        local c=LocalPlayer.Character; local r=c and c:FindFirstChild("HumanoidRootPart"); local h=c and c:FindFirstChildOfClass("Humanoid"); if not r or not h then return end; h.PlatformStand=true
        if onTarget then
            stayTimer=stayTimer+dt; local tgt=lastTgt or getWB2Target()
            if tgt and tgt.Parent then r.CFrame=CFrame.new(tgt.Position+Vector3.new((math.random()-0.5)*0.3,4,(math.random()-0.5)*0.3)) end
            if stayTimer>=STAY_TIME then wb2Unanchor(); r.CFrame=CFrame.new(wb2VoidX,WB2Settings.VoidDepth,wb2VoidZ); wb2Anchor(r,wb2VoidX,wb2VoidZ); onTarget=false; stayTimer=0; timer=0; lastTgt=nil end
        else
            timer=timer+dt
            if timer>=WB2Settings.Interval then
                local tgt=getWB2Target()
                if tgt then wb2Unanchor(); r.CFrame=CFrame.new(tgt.Position+Vector3.new((math.random()-0.5)*0.3,4,(math.random()-0.5)*0.3)); onTarget=true; stayTimer=0; lastTgt=tgt end; timer=0
            end
        end
    end)
end
local function stopWB2() WB2Settings.Enabled=false; if wb2Conn then wb2Conn:Disconnect();wb2Conn=nil end; wb2Unanchor(); wb2ShowChar(); local char=LocalPlayer.Character; if char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end end end

local WB3Settings={Enabled=false,Target="",SpinSpeed=25,VoidDepth=-500,Interval=0.08}
local wb3Conn=nil; local wb3SpinConn=nil; local wb3Hidden={}; local wb3VoidX=0; local wb3VoidZ=0; local wb3BP=nil; local wb3BG=nil; local wb3Angle=0
local function getWB3Target()
    if WB3Settings.Target~="" then for _,plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer and plr.Name==WB3Settings.Target then local c=plr.Character; local r=c and c:FindFirstChild("HumanoidRootPart"); if r then return r end end end end
    local best,bestDist=nil,math.huge
    for _,plr in ipairs(Players:GetPlayers()) do
        repeat if plr==LocalPlayer then break end; local c=plr.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); local hum=c and c:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health<=0 then break end; if root.Position.Y<-200 then break end; if not c.Parent then break end
        local myRoot=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); local myPos=myRoot and myRoot.Position or Vector3.zero
        local d=(root.Position-myPos).Magnitude; if d<bestDist then bestDist=d;best=root end; until true
    end; return best
end
local function wb3HideChar() local char=LocalPlayer.Character; if not char then return end; wb3Hidden={}; for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then table.insert(wb3Hidden,{part=p,orig=p.LocalTransparencyModifier}); p.LocalTransparencyModifier=1 end end end
local function wb3ShowChar() for _,e in ipairs(wb3Hidden) do pcall(function() e.part.LocalTransparencyModifier=e.orig end) end; wb3Hidden={} end
local function wb3Anchor(root,voidX,voidZ)
    if not wb3BP or not wb3BP.Parent then wb3BP=Instance.new("BodyPosition"); wb3BP.MaxForce=Vector3.new(1e5,1e5,1e5); wb3BP.D=500; wb3BP.P=10000; wb3BP.Parent=root end; wb3BP.Position=Vector3.new(voidX,WB3Settings.VoidDepth,voidZ)
    if not wb3BG or not wb3BG.Parent then wb3BG=Instance.new("BodyGyro"); wb3BG.MaxTorque=Vector3.new(1e5,1e5,1e5); wb3BG.P=10000; wb3BG.Parent=root end; wb3BG.CFrame=CFrame.new(root.Position)
end
local function wb3Unanchor() if wb3BP and wb3BP.Parent then wb3BP:Destroy();wb3BP=nil end; if wb3BG and wb3BG.Parent then wb3BG:Destroy();wb3BG=nil end end
local _wb3OrigJoints={}
local function wb3SaveJoints(char) _wb3OrigJoints={}; for _,m in ipairs(char:GetDescendants()) do if m:IsA("Motor6D") then _wb3OrigJoints[m]={C0=m.C0,C1=m.C1} end end end
local function wb3RestoreJoints() for m,orig in pairs(_wb3OrigJoints) do pcall(function() m.C0=orig.C0; m.C1=orig.C1 end) end; _wb3OrigJoints={} end
local function startWB3()
    if wb3Conn then wb3Conn:Disconnect() end; if wb3SpinConn then wb3SpinConn:Disconnect() end; wb3HideChar(); wb3Angle=0
    local char=LocalPlayer.Character; if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart"); local hum=char:FindFirstChildOfClass("Humanoid"); if not root or not hum then return end
    hum.PlatformStand=true; wb3VoidX=root.Position.X; wb3VoidZ=root.Position.Z
    root.CFrame=CFrame.new(wb3VoidX,WB3Settings.VoidDepth,wb3VoidZ); wb3Anchor(root,wb3VoidX,wb3VoidZ); wb3SaveJoints(char)
    wb3SpinConn=RunService.RenderStepped:Connect(function(dt)
        if not WB3Settings.Enabled then return end; local c2=LocalPlayer.Character; if not c2 then return end
        wb3Angle=wb3Angle+WB3Settings.SpinSpeed*dt; local i=0
        for _,m in ipairs(c2:GetDescendants()) do
            if m:IsA("Motor6D") and _wb3OrigJoints[m] then i=i+1; local orig=_wb3OrigJoints[m]; local phase=(i*1.3)
                m.C0=orig.C0*CFrame.Angles(math.sin(wb3Angle+phase)*math.pi,math.cos(wb3Angle*0.7+phase)*math.pi,math.sin(wb3Angle*1.3+phase)*math.pi)
            end
        end
    end)
    local timer=0; local stayTimer=0; local onTarget=false; local lastTgt=nil; local STAY_TIME=0.325
    wb3Conn=RunService.Heartbeat:Connect(function(dt)
        if not WB3Settings.Enabled then return end; local c=LocalPlayer.Character; local r=c and c:FindFirstChild("HumanoidRootPart"); local h=c and c:FindFirstChildOfClass("Humanoid"); if not r or not h then return end; h.PlatformStand=true
        if onTarget then
            stayTimer=stayTimer+dt; local tgt=lastTgt or getWB3Target()
            if tgt and tgt.Parent then r.CFrame=CFrame.new(tgt.Position+Vector3.new((math.random()-0.5)*0.3,4,(math.random()-0.5)*0.3)) end
            if stayTimer>=STAY_TIME then wb3Unanchor(); r.CFrame=CFrame.new(wb3VoidX,WB3Settings.VoidDepth,wb3VoidZ); wb3Anchor(r,wb3VoidX,wb3VoidZ); onTarget=false; stayTimer=0; timer=0; lastTgt=nil end
        else
            timer=timer+dt
            if timer>=WB3Settings.Interval then local tgt=getWB3Target(); if tgt then wb3Unanchor(); r.CFrame=CFrame.new(tgt.Position+Vector3.new((math.random()-0.5)*0.3,4,(math.random()-0.5)*0.3)); onTarget=true; stayTimer=0; lastTgt=tgt end; timer=0 end
        end
    end)
end
local function stopWB3()
    WB3Settings.Enabled=false
    if wb3Conn then wb3Conn:Disconnect();wb3Conn=nil end; if wb3SpinConn then wb3SpinConn:Disconnect();wb3SpinConn=nil end
    wb3RestoreJoints(); wb3Unanchor(); wb3ShowChar()
    local char=LocalPlayer.Character; if char then local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end end
end

-- Anti Katana
local AntiKatanaSettings={Enabled=false,ShowIndicator=true}
local _akConn=nil; local _akBlocked=false; local _akIndicatorLbl=nil; local _akTimers={}; local DEFLECT_WINDOW=1.1
local function getKatanaTool(char) if not char then return nil end; for _,child in ipairs(char:GetChildren()) do if child:IsA("Tool") then local n=child.Name:lower(); if n:find("katana") or n:find("saber") then return child end end end; return nil end
local function isDeflecting(plr)
    if _akTimers[plr] and _akTimers[plr]>0 then return true end
    local char=plr.Character; if not char then return false end; local tool=getKatanaTool(char); if not tool then return false end
    local attrOk,attrVal=pcall(function() return tool:GetAttribute("Deflecting") end); if attrOk and attrVal==true then return true end
    local bv=tool:FindFirstChild("Deflecting"); if bv and bv:IsA("BoolValue") and bv.Value then return true end
    local handle=tool:FindFirstChild("Handle")
    if handle then
        if handle:FindFirstChildOfClass("PointLight") then return true end; if handle:FindFirstChildOfClass("SelectionBox") then return true end
        for _,d in ipairs(handle:GetChildren()) do if d:IsA("BasePart") then local pn=d.Name:lower(); if pn:find("glow") or pn:find("shine") or pn:find("deflect") then return true end end end
        local lg=handle:FindFirstChild("LeftGrip"); if lg and lg:IsA("Weld") then return true end
    end; return false
end
local function watchCharForKatana(plr,char)
    if not char then return end
    char.ChildAdded:Connect(function(child)
        if not child:IsA("Tool") then return end; local n=child.Name:lower(); if not (n:find("katana") or n:find("saber")) then return end
        child.Activated:Connect(function() _akTimers[plr]=DEFLECT_WINDOW end)
        local handle=child:FindFirstChild("Handle")
        if handle then
            handle.ChildAdded:Connect(function(c) if c:IsA("PointLight") or c:IsA("SelectionBox") or (c:IsA("BasePart") and (c.Name:lower():find("glow") or c.Name:lower():find("shine"))) then _akTimers[plr]=DEFLECT_WINDOW end end)
            handle.ChildAdded:Connect(function(c) if c:IsA("Weld") and c.Name=="LeftGrip" then _akTimers[plr]=DEFLECT_WINDOW end end)
        end
        child.AttributeChanged:Connect(function(attr) if attr=="Deflecting" then local ok,v=pcall(function() return child:GetAttribute("Deflecting") end); if ok and v then _akTimers[plr]=DEFLECT_WINDOW end end end)
    end)
end
local function startAntiKatana()
    if _akConn then _akConn:Disconnect() end; _akTimers={}; _akBlocked=false
    if not _akIndicatorLbl then local ok,lbl=pcall(function() return Drawing.new("Text") end); if ok and lbl then lbl.Text="KATANA DEFLECT - HOLDING FIRE"; lbl.Size=18; lbl.Font=2; lbl.Color=Color3.fromRGB(255,70,70); lbl.Outline=true; lbl.OutlineColor=Color3.new(0,0,0); lbl.Center=true; lbl.Visible=false; _akIndicatorLbl=lbl end end
    for _,plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer then watchCharForKatana(plr,plr.Character); plr.CharacterAdded:Connect(function(char) _akTimers[plr]=nil; watchCharForKatana(plr,char) end) end end
    Players.PlayerAdded:Connect(function(plr) if plr==LocalPlayer then return end; watchCharForKatana(plr,plr.Character); plr.CharacterAdded:Connect(function(char) _akTimers[plr]=nil; watchCharForKatana(plr,char) end) end)
    _akConn=RunService.Heartbeat:Connect(function(dt)
        if not AntiKatanaSettings.Enabled then _akBlocked=false; if _akIndicatorLbl then _akIndicatorLbl.Visible=false end; return end
        for plr,t in pairs(_akTimers) do _akTimers[plr]=t-dt; if _akTimers[plr]<=0 then _akTimers[plr]=nil end end
        local blocking=false
        for _,plr in ipairs(Players:GetPlayers()) do repeat if plr==LocalPlayer then break end; local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then break end; if isDeflecting(plr) then blocking=true end until true; if blocking then break end end
        _akBlocked=blocking; if _akBlocked then pcall(mouse1release) end
        if _akIndicatorLbl then local vp=Camera.ViewportSize; _akIndicatorLbl.Position=Vector2.new(vp.X/2,80); _akIndicatorLbl.Visible=_akBlocked and AntiKatanaSettings.ShowIndicator end
    end)
end
local function stopAntiKatana() if _akConn then _akConn:Disconnect();_akConn=nil end; _akBlocked=false; _akTimers={}; if _akIndicatorLbl then pcall(function() _akIndicatorLbl.Visible=false end) end end

-- Rivals Spoof
local RivalsSpoof={NameEnabled=false,FakeName="Player",StreakEnabled=false,FakeStreak="999",RankEnabled=false,FakeRank="Gold 3",LevelEnabled=false,FakeLevel="999",ELOEnabled=false,FakeELO="9,999"}
local RANK_LIST={"Bronze 1","Bronze 2","Bronze 3","Silver 1","Silver 2","Silver 3","Gold 1","Gold 2","Gold 3","Platinum 1","Platinum 2","Platinum 3","Diamond 1","Diamond 2","Diamond 3","Archnemesis"}
local function deepGet(root,...) local cur=root; for _,key in ipairs({...}) do if cur==nil then return nil end; cur=cur:FindFirstChild(key) end; return cur end
local function spoofTeamSlots(teamFrame)
    if not teamFrame then return end; local teamSlot=teamFrame:FindFirstChild("DuelScoresTeamSlot"); if not teamSlot then return end
    local teammates=deepGet(teamSlot,"Container","Teammates"); if not teammates then return end
    for _,slot in ipairs(teammates:GetChildren()) do
        if slot.Name=="TeammateSlot" then local container=slot:FindFirstChild("Container")
            if container then
                if RivalsSpoof.StreakEnabled then local sv=deepGet(container,"Streak","Value"); if sv and sv:IsA("TextLabel") then sv.Text=RivalsSpoof.FakeStreak end end
                if RivalsSpoof.LevelEnabled then local lv=deepGet(container,"Level","Title"); if lv and lv:IsA("TextLabel") then lv.Text=RivalsSpoof.FakeLevel end end
            end
        end
    end
end

-- CharacterAdded
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if UnderSettings.Enabled then hideLocalChar();startUnder() end
    if WB2Settings.Enabled then wb2HideChar();startWB2() end
    if WB3Settings.Enabled then wb3HideChar();startWB3() end
    if FlySettings.Enabled then startFly() end
    if VFlySettings.Enabled then startVFly() end
    if SkyFlySettings.Enabled then startSkyFly() end
end)

-- ============================================================
-- GUI - ROUGE/NOIR - COMPACT - DRAGGABLE
-- ============================================================
pcall(function() CoreGui:FindFirstChild("AzyroXHub"):Destroy() end)

local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AzyroXHub"; ScreenGui.Parent=CoreGui; ScreenGui.ResetOnSpawn=false; ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Global; ScreenGui.DisplayOrder=999

local OverlayLayer=Instance.new("Frame")
OverlayLayer.Size=UDim2.new(1,0,1,0); OverlayLayer.BackgroundTransparency=1; OverlayLayer.ZIndex=900; OverlayLayer.Parent=ScreenGui

-- Toggle button (toujours visible)
local ToggleBtn=Instance.new("TextButton")
ToggleBtn.Size=UDim2.new(0,44,0,44); ToggleBtn.Position=UDim2.new(0,8,0,8)
ToggleBtn.BackgroundColor3=Color3.fromRGB(20,0,0); ToggleBtn.BorderSizePixel=0
ToggleBtn.Text="AZ"; ToggleBtn.TextColor3=Color3.fromRGB(220,40,40)
ToggleBtn.Font=Enum.Font.GothamBlack; ToggleBtn.TextSize=15; ToggleBtn.Parent=ScreenGui
Instance.new("UICorner",ToggleBtn).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",ToggleBtn).Color=Color3.fromRGB(180,20,20)

-- Main window - COMPACT 380x460
local Main=Instance.new("Frame")
Main.Size=UDim2.new(0,380,0,460); Main.Position=UDim2.new(0,60,0,8)
Main.BackgroundColor3=Color3.fromRGB(10,0,0); Main.BorderSizePixel=0; Main.Visible=false; Main.ZIndex=1; Main.Parent=ScreenGui
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",Main).Color=Color3.fromRGB(140,15,15)

-- TitleBar
local TBar=Instance.new("Frame")
TBar.Size=UDim2.new(1,0,0,32); TBar.BackgroundColor3=Color3.fromRGB(20,0,0); TBar.BorderSizePixel=0; TBar.ZIndex=2; TBar.Parent=Main
Instance.new("UICorner",TBar).CornerRadius=UDim.new(0,8)
Instance.new("Frame",TBar).Size=UDim2.new(1,0,0,8); TBar:FindFirstChildOfClass("Frame").Position=UDim2.new(0,0,1,-8); TBar:FindFirstChildOfClass("Frame").BackgroundColor3=Color3.fromRGB(20,0,0); TBar:FindFirstChildOfClass("Frame").BorderSizePixel=0

local dot1=Instance.new("Frame"); dot1.Size=UDim2.new(0,7,0,7); dot1.Position=UDim2.new(0,10,0.5,-3.5); dot1.BackgroundColor3=Color3.fromRGB(220,40,40); dot1.BorderSizePixel=0; dot1.Parent=TBar; Instance.new("UICorner",dot1).CornerRadius=UDim.new(1,0)
local TLabel=Instance.new("TextLabel"); TLabel.Text="AZYROX HUB"; TLabel.Font=Enum.Font.GothamBold; TLabel.TextSize=13; TLabel.TextColor3=Color3.fromRGB(220,220,220); TLabel.TextXAlignment=Enum.TextXAlignment.Left; TLabel.BackgroundTransparency=1; TLabel.Size=UDim2.new(1,-80,1,0); TLabel.Position=UDim2.new(0,24,0,0); TLabel.ZIndex=3; TLabel.Parent=TBar

local CloseBtn=Instance.new("TextButton"); CloseBtn.Text="X"; CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextSize=13; CloseBtn.TextColor3=Color3.fromRGB(180,180,180); CloseBtn.BackgroundColor3=Color3.fromRGB(180,30,30); CloseBtn.BackgroundTransparency=1; CloseBtn.Size=UDim2.new(0,26,0,26); CloseBtn.Position=UDim2.new(1,-30,0.5,-13); CloseBtn.BorderSizePixel=0; CloseBtn.ZIndex=3; CloseBtn.Parent=TBar
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,5)
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.12),{BackgroundTransparency=0,TextColor3=Color3.new(1,1,1)}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.12),{BackgroundTransparency=1,TextColor3=Color3.fromRGB(180,180,180)}):Play() end)
CloseBtn.MouseButton1Click:Connect(function()
    for p in pairs(ESPObjects) do removeESP(p) end
    stopFly();stopVFly();stopOrbit();stopUnder();stopSkyFly();unhookSilentAim()
    pcall(function() FOVCircle:Remove() end); pcall(function() FOVRing:Remove() end)
    pcall(function() TargetDot:Remove() end); pcall(function() DotGlow1:Remove() end); pcall(function() DotGlow2:Remove() end)
    ScreenGui:Destroy()
end)

-- Drag
do
    local dragging,dragStart,startPos=false,nil,nil
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=i.Position; startPos=Main.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dragStart
            Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
end

-- Toggle visibility
local guiOpen=false
ToggleBtn.MouseButton1Click:Connect(function() guiOpen=not guiOpen; Main.Visible=guiOpen end)
UIS.InputBegan:Connect(function(i,gp) if gp then return end; if i.KeyCode==Enum.KeyCode.RightShift then guiOpen=not guiOpen; Main.Visible=guiOpen end end)

-- Sidebar
local Sidebar=Instance.new("Frame"); Sidebar.Size=UDim2.new(0,80,1,-32); Sidebar.Position=UDim2.new(0,0,0,32); Sidebar.BackgroundColor3=Color3.fromRGB(16,0,0); Sidebar.BorderSizePixel=0; Sidebar.ZIndex=2; Sidebar.Parent=Main
Instance.new("UICorner",Sidebar).CornerRadius=UDim.new(0,8)
Instance.new("Frame",Main).Size=UDim2.new(0,1,1,-32); Instance.new("Frame",Main):FindFirstChildOfClass("Frame") -- divider trick

local SidDiv=Instance.new("Frame"); SidDiv.Size=UDim2.new(0,1,1,-32); SidDiv.Position=UDim2.new(0,80,0,32); SidDiv.BackgroundColor3=Color3.fromRGB(80,8,8); SidDiv.BorderSizePixel=0; SidDiv.ZIndex=2; SidDiv.Parent=Main

-- Content
local ContentOuter=Instance.new("Frame"); ContentOuter.Size=UDim2.new(1,-81,1,-32); ContentOuter.Position=UDim2.new(0,81,0,32); ContentOuter.BackgroundTransparency=1; ContentOuter.ClipsDescendants=true; ContentOuter.ZIndex=2; ContentOuter.Parent=Main

-- Theme colors (rouge/noir)
local T={
    BG=Color3.fromRGB(10,0,0), Panel=Color3.fromRGB(16,0,0), Card=Color3.fromRGB(22,4,4),
    Accent=Color3.fromRGB(220,40,40), AccentDim=Color3.fromRGB(150,20,20), AccentDrk=Color3.fromRGB(60,8,8),
    TxtHi=Color3.fromRGB(240,220,220), TxtMid=Color3.fromRGB(170,100,100), TxtLo=Color3.fromRGB(90,40,40),
    Border=Color3.fromRGB(60,8,8), BorderHi=Color3.fromRGB(100,20,20),
    TON=Color3.fromRGB(220,40,40), TOFF=Color3.fromRGB(50,10,10), DropBG=Color3.fromRGB(8,0,0),
}

local function tw(obj,props,t) TweenService:Create(obj,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props):Play() end
local function mk(class,props,parent) local i=Instance.new(class); for k,v in pairs(props) do i[k]=v end; i.Parent=parent; return i end

-- Tab system
local TAB_NAMES={"Rage","Rage+","Aimbot","Visuals","Sound","Config"}
local TabBtns={}; local TabPages={}; local openDropdown=nil

local function selectTab(name)
    for _,n in ipairs(TAB_NAMES) do
        if TabBtns[n] then tw(TabBtns[n],{TextColor3=T.TxtLo,BackgroundTransparency=1}) end
        if TabPages[n] then TabPages[n].Visible=false end
    end
    if TabBtns[name] then tw(TabBtns[name],{TextColor3=T.Accent,BackgroundTransparency=0.8}) end
    if TabPages[name] then TabPages[name].Visible=true end
end

for i,tname in ipairs(TAB_NAMES) do
    local btn=mk("TextButton",{Text=tname,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TxtLo,BackgroundColor3=T.AccentDrk,BackgroundTransparency=1,Size=UDim2.new(1,-8,0,28),Position=UDim2.new(0,4,0,6+(i-1)*32),BorderSizePixel=0,ZIndex=3},Sidebar)
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5); TabBtns[tname]=btn
    local page=mk("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=T.AccentDim,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,ZIndex=2},ContentOuter)
    mk("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},page)
    mk("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},page)
    TabPages[tname]=page
    btn.MouseButton1Click:Connect(function() selectTab(tname) end)
end

-- Widget builder
local function buildSection(tabName,title)
    local page=TabPages[tabName]; local sec={}
    local sf=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=T.Card,BorderSizePixel=0,ZIndex=3},page)
    Instance.new("UICorner",sf).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",sf).Color=T.Border
    local si=mk("Frame",{Size=UDim2.new(1,0,1,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=3},sf)
    mk("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},si)
    mk("UIPadding",{PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},si)
    sec.si=si
    mk("TextLabel",{Text=title,Font=Enum.Font.GothamBold,TextSize=9,TextColor3=T.AccentDim,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(1,0,0,14),ZIndex=4},si)
    mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=T.Border,BorderSizePixel=0,ZIndex=4},si)

    function sec:Toggle(label,default,cb)
        local state=default or false
        local row=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,ZIndex=4},si)
        mk("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TxtHi,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(1,-44,1,0),ZIndex=4},row)
        local track=mk("Frame",{Size=UDim2.new(0,34,0,16),Position=UDim2.new(1,-34,0.5,-8),BackgroundColor3=state and T.TON or T.TOFF,BorderSizePixel=0,ZIndex=4},row)
        Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
        local knob=mk("Frame",{Size=UDim2.new(0,11,0,11),Position=state and UDim2.new(1,-14,0.5,-5.5) or UDim2.new(0,3,0.5,-5.5),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=5},track)
        Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
        mk("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=6},row).MouseButton1Click:Connect(function()
            state=not state; tw(track,{BackgroundColor3=state and T.TON or T.TOFF}); tw(knob,{Position=state and UDim2.new(1,-14,0.5,-5.5) or UDim2.new(0,3,0.5,-5.5)}); if cb then cb(state) end
        end)
        return {GetState=function() return state end}
    end

    function sec:Button(label,cb)
        local b=mk("TextButton",{Text=label,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=T.Accent,BackgroundColor3=T.AccentDrk,Size=UDim2.new(1,0,0,26),BorderSizePixel=0,ZIndex=4},si)
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5); Instance.new("UIStroke",b).Color=T.AccentDim
        b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=T.AccentDim,TextColor3=Color3.new(1,1,1)}) end)
        b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=T.AccentDrk,TextColor3=T.Accent}) end)
        b.MouseButton1Click:Connect(function() if cb then cb() end end)
    end

    function sec:Slider(label,min,max,default,cb)
        local val=default or min
        local cont=mk("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,ZIndex=4},si)
        local hdr=mk("Frame",{Size=UDim2.new(1,0,0,15),BackgroundTransparency=1,ZIndex=4},cont)
        mk("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TxtHi,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(0.7,0,1,0),ZIndex=4},hdr)
        local vLbl=mk("TextLabel",{Text=tostring(val),Font=Enum.Font.GothamBold,TextSize=10,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Right,BackgroundTransparency=1,Size=UDim2.new(0.3,0,1,0),Position=UDim2.new(0.7,0,0,0),ZIndex=4},hdr)
        local trk=mk("Frame",{Size=UDim2.new(1,0,0,4),Position=UDim2.new(0,0,0,20),BackgroundColor3=T.Border,BorderSizePixel=0,ZIndex=4},cont)
        Instance.new("UICorner",trk).CornerRadius=UDim.new(1,0)
        local r0=(val-min)/(max-min)
        local fill=mk("Frame",{Size=UDim2.new(r0,0,1,0),BackgroundColor3=T.Accent,BorderSizePixel=0,ZIndex=5},trk); Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
        local knob=mk("Frame",{Size=UDim2.new(0,9,0,9),Position=UDim2.new(r0,-4.5,0.5,-4.5),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=6},trk); Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
        local hb=mk("TextButton",{Size=UDim2.new(1,0,0,34),Position=UDim2.new(0,0,0,-15),BackgroundTransparency=1,Text="",ZIndex=7},trk)
        local sliding=false
        local function upd(i) local r=math.clamp((i.Position.X-trk.AbsolutePosition.X)/trk.AbsoluteSize.X,0,1); val=math.floor(min+r*(max-min)); vLbl.Text=tostring(val); tw(fill,{Size=UDim2.new(r,0,1,0)},0.04); tw(knob,{Position=UDim2.new(r,-4.5,0.5,-4.5)},0.04); if cb then cb(val) end end
        hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true;upd(i) end end)
        UIS.InputChanged:Connect(function(i) if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i) end end)
        UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end end)
    end

    function sec:Label(text)
        mk("TextLabel",{Text=text,Font=Enum.Font.Gotham,TextSize=10,TextColor3=T.TxtMid,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(1,0,0,16),TextWrapped=true,ZIndex=4},si)
    end

    function sec:TextInput(label,default,placeholder,cb)
        mk("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TxtHi,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(1,0,0,15),ZIndex=4},si)
        local tb=mk("TextBox",{Text=default or "",Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.Accent,PlaceholderText=placeholder or "...",PlaceholderColor3=T.TxtLo,BackgroundColor3=T.DropBG,BorderSizePixel=0,Size=UDim2.new(1,0,0,24),ZIndex=4,ClearTextOnFocus=false},si)
        Instance.new("UICorner",tb).CornerRadius=UDim.new(0,5); Instance.new("UIStroke",tb).Color=T.BorderHi; mk("UIPadding",{PaddingLeft=UDim.new(0,7)},tb)
        tb.FocusLost:Connect(function() if cb then cb(tb.Text) end end); return tb
    end

    function sec:Dropdown(label,options,default,cb)
        local selected=default or options[1]; local isOpen=false; local floatFrame=nil; local justSelected=false
        mk("TextLabel",{Text=label,Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TxtHi,TextXAlignment=Enum.TextXAlignment.Left,BackgroundTransparency=1,Size=UDim2.new(1,0,0,15),ZIndex=4},si)
        local anchor=mk("TextButton",{Text="  "..selected.."  v",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=T.Accent,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=T.DropBG,Size=UDim2.new(1,0,0,24),BorderSizePixel=0,ZIndex=4},si)
        Instance.new("UICorner",anchor).CornerRadius=UDim.new(0,5); Instance.new("UIStroke",anchor).Color=T.BorderHi
        local thisDD={}
        local function closeDD()
            isOpen=false; if openDropdown==thisDD then openDropdown=nil end; anchor.Text="  "..selected.."  v"
            if floatFrame then local w=floatFrame.Size.X.Offset; tw(floatFrame,{Size=UDim2.new(0,w,0,0)},0.1); local ff=floatFrame; floatFrame=nil; task.delay(0.11,function() pcall(function() ff:Destroy() end) end) end
        end
        local function openDD()
            if openDropdown and openDropdown~=thisDD then openDropdown.close() end
            if floatFrame then pcall(function() floatFrame:Destroy() end); floatFrame=nil end
            isOpen=true; openDropdown=thisDD; anchor.Text="  "..selected.."  ^"
            local ap=anchor.AbsolutePosition; local as=anchor.AbsoluteSize; local dropH=#options*26
            floatFrame=mk("Frame",{Position=UDim2.new(0,ap.X,0,ap.Y+as.Y+2),Size=UDim2.new(0,as.X,0,0),BackgroundColor3=T.DropBG,BorderSizePixel=0,ZIndex=950,ClipsDescendants=true},OverlayLayer)
            Instance.new("UICorner",floatFrame).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",floatFrame).Color=T.AccentDim
            mk("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},floatFrame)
            tw(floatFrame,{Size=UDim2.new(0,as.X,0,dropH)},0.12)
            for _,opt in ipairs(options) do
                local isSel=(opt==selected)
                local ob=mk("TextButton",{Text="  "..opt,Font=Enum.Font.Gotham,TextSize=12,TextColor3=isSel and T.Accent or T.TxtMid,TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=T.AccentDrk,BackgroundTransparency=isSel and 0.5 or 1,Size=UDim2.new(1,0,0,26),BorderSizePixel=0,ZIndex=951},floatFrame)
                ob.MouseEnter:Connect(function() if opt~=selected then tw(ob,{TextColor3=T.TxtHi,BackgroundTransparency=0.7}) end end)
                ob.MouseLeave:Connect(function() if opt~=selected then tw(ob,{TextColor3=T.TxtMid,BackgroundTransparency=1}) end end)
                ob.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        justSelected=true; selected=opt; anchor.Text="  "..selected.."  v"; if cb then cb(selected) end; closeDD(); task.defer(function() justSelected=false end)
                    end
                end)
            end
        end
        thisDD.close=closeDD
        anchor.MouseButton1Click:Connect(function() if isOpen then closeDD() else openDD() end end)
        UIS.InputBegan:Connect(function(i) if isOpen and not justSelected and i.UserInputType==Enum.UserInputType.MouseButton1 then task.defer(function() if isOpen and not justSelected then closeDD() end end) end end)
        return {GetSelected=function() return selected end}
    end

    return sec
end

-- ============================================================
-- POPULATE TABS
-- ============================================================
local function getPlayerNames()
    local n={"(Nearest)"}; for _,plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer then table.insert(n,plr.Name) end end; return n
end

-- RAGE
local ragOrbitSec=buildSection("Rage","Orbit Player")
ragOrbitSec:Label("Circles around the target endlessly.")
ragOrbitSec:Toggle("Orbit",false,function(s) OrbitSettings.Enabled=s; if s then FlySettings.Enabled=false;stopFly();VFlySettings.Enabled=false;stopVFly();UnderSettings.Enabled=false;stopUnder();stopWB2();local char=LocalPlayer.Character;local hum=char and char:FindFirstChildOfClass("Humanoid");if hum then hum.PlatformStand=true end;startOrbit() else stopOrbit();local char=LocalPlayer.Character;local hum=char and char:FindFirstChildOfClass("Humanoid");if hum then hum.PlatformStand=false end end end)
ragOrbitSec:Dropdown("Orbit Target",getPlayerNames(),"(Nearest)",function(sel) OrbitSettings.Target=sel=="(Nearest)" and "" or sel end)
ragOrbitSec:Slider("Orbit Radius",4,40,10,function(v) OrbitSettings.Radius=v end)
ragOrbitSec:Slider("Orbit Speed",1,20,5,function(v) OrbitSettings.Speed=v/3 end)

local wb1Sec=buildSection("Rage","Wallbang V1 - Under Player")
wb1Sec:Label("Locks you under the target. Invisible to yourself.")
wb1Sec:Toggle("Wallbang V1",false,function(s) UnderSettings.Enabled=s; if s then FlySettings.Enabled=false;stopFly();VFlySettings.Enabled=false;stopVFly();OrbitSettings.Enabled=false;stopOrbit();stopWB2();startUnder() else stopUnder() end end)
wb1Sec:Toggle("Safe Mode (anti-detect)",true,function(s) UnderSettings.SafeMode=s end)
wb1Sec:Dropdown("V1 Target",getPlayerNames(),"(Nearest)",function(sel) UnderSettings.Target=sel=="(Nearest)" and "" or sel end)
wb1Sec:Slider("V1 Depth (studs below)",-8,0,-4,function(v) UnderSettings.Offset=v end)
wb1Sec:Toggle("Auto Shoot",true,function(s) UnderSettings.AutoShoot=s;underShootTimer=0 end)
wb1Sec:Slider("Shoot Rate (clicks/sec)",1,10,5,function(v) UnderSettings.ShootRate=1/v end)

local wb2Sec=buildSection("Rage","Wallbang V2 - Void Flash")
wb2Sec:Label("Drops you into the void. Flashes onto target.")
wb2Sec:Toggle("Wallbang V2",false,function(s) WB2Settings.Enabled=s; if s then FlySettings.Enabled=false;stopFly();VFlySettings.Enabled=false;stopVFly();OrbitSettings.Enabled=false;stopOrbit();UnderSettings.Enabled=false;stopUnder();startWB2() else stopWB2() end end)
wb2Sec:Dropdown("V2 Target",getPlayerNames(),"(Nearest)",function(sel) WB2Settings.Target=sel=="(Nearest)" and "" or sel end)
wb2Sec:Slider("Flash Rate (lower=faster)",2,20,8,function(v) WB2Settings.Interval=v/100 end)
wb2Sec:Slider("Void Depth",-2000,-100,-500,function(v) WB2Settings.VoidDepth=v end)

local wb3Sec=buildSection("Rage","Wallbang V3 - Joint Spin")
wb3Sec:Label("Void + joint spin. Hits through walls.")
wb3Sec:Toggle("Wallbang V3",false,function(s) WB3Settings.Enabled=s; if s then FlySettings.Enabled=false;stopFly();VFlySettings.Enabled=false;stopVFly();OrbitSettings.Enabled=false;stopOrbit();UnderSettings.Enabled=false;stopUnder();WB2Settings.Enabled=false;stopWB2();startWB3() else stopWB3() end end)
wb3Sec:Dropdown("V3 Target",getPlayerNames(),"(Nearest)",function(sel) WB3Settings.Target=sel=="(Nearest)" and "" or sel end)
wb3Sec:Slider("Spin Speed",1,100,25,function(v) WB3Settings.SpinSpeed=v end)
wb3Sec:Slider("Flash Rate (lower=faster)",2,20,8,function(v) WB3Settings.Interval=v/100 end)
wb3Sec:Slider("Void Depth",-2000,-100,-500,function(v) WB3Settings.VoidDepth=v end)

local skyFlySec=buildSection("Rage","Sky Fly")
skyFlySec:Label("Launches you high into the sky. WASD/Space/Ctrl.")
skyFlySec:Toggle("Sky Fly",false,function(s) SkyFlySettings.Enabled=s; if s then stopFly();stopVFly();stopOrbit();stopUnder();stopWB2();stopWB3();startSkyFly() else stopSkyFly() end end)
skyFlySec:Slider("Speed",20,300,80,function(v) SkyFlySettings.Speed=v end)
skyFlySec:Slider("Launch Height (studs)",100,2000,400,function(v) SkyFlySettings.Height=v end)

-- RAGE+
local MovementSettings={RemoveAnims=false,InfiniteJump=false}
local _movConn=nil;local _ijConn=nil;local _animConn=nil;local _savedJoints={}
local function getAnimateScript(char) return char:FindFirstChild("Animate") end
local function saveJoints(char) _savedJoints={}; for _,m in ipairs(char:GetDescendants()) do if m:IsA("Motor6D") and m.Part0 and m.Part1 then _savedJoints[m]={C0=m.C0,C1=m.C1} end end end
local function applyMovement()
    if _movConn then _movConn:Disconnect();_movConn=nil end; if _animConn then _animConn:Disconnect();_animConn=nil end
    local char=LocalPlayer.Character
    if not MovementSettings.RemoveAnims then if char then local a=getAnimateScript(char); if a then a.Disabled=false end end; _savedJoints={}; return end
    if not char then return end; local animScript=getAnimateScript(char); if animScript then animScript.Disabled=true end
    local hum=char:FindFirstChildOfClass("Humanoid"); local anim=hum and hum:FindFirstChildOfClass("Animator")
    if anim then for _,t in ipairs(anim:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end; _animConn=anim.AnimationPlayed:Connect(function(t) if MovementSettings.RemoveAnims then pcall(function() t:Stop(0) end) end end) end
    task.wait(0.05); saveJoints(char)
    _movConn=RunService.Heartbeat:Connect(function() if not MovementSettings.RemoveAnims then return end; local c=LocalPlayer.Character; if not c then return end; for m,saved in pairs(_savedJoints) do if m and m.Parent then m.C0=saved.C0;m.C1=saved.C1 end end; local h=c:FindFirstChildOfClass("Humanoid"); if h then h.CameraOffset=Vector3.zero end end)
end
local function applyInfiniteJump() if _ijConn then _ijConn:Disconnect();_ijConn=nil end; if not MovementSettings.InfiniteJump then return end; _ijConn=UIS.JumpRequest:Connect(function() local char=LocalPlayer.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end end) end
LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); if _movConn then _movConn:Disconnect();_movConn=nil end; if _animConn then _animConn:Disconnect();_animConn=nil end; _savedJoints={}; if MovementSettings.RemoveAnims then applyMovement() end; applyInfiniteJump() end)

local animSec=buildSection("Rage+","Remove Animations")
animSec:Label("Removes walk/run/jump/fall animations.")
animSec:Toggle("Remove Animations",false,function(s) MovementSettings.RemoveAnims=s;applyMovement() end)

local _cfpConn=nil;local _cfpEnabled=false
local function setArmVisibility(char,visible) if not char then return end; local val=visible and 0 or 1; for _,n in ipairs({"RightUpperArm","RightLowerArm","RightHand","LeftUpperArm","LeftLowerArm","LeftHand"}) do local p=char:FindFirstChild(n); if p and p:IsA("BasePart") then pcall(function() p.LocalTransparencyModifier=val end) end end; for _,child in ipairs(char:GetChildren()) do if child:IsA("Tool") then for _,p in ipairs(child:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.LocalTransparencyModifier=val end) end end end end end
local function startCleanFP() if _cfpConn then _cfpConn:Disconnect();_cfpConn=nil end; _cfpConn=RunService.RenderStepped:Connect(function() if not _cfpEnabled then return end; local char=LocalPlayer.Character; if not char then return end; local isFP=Camera.CameraType==Enum.CameraType.Custom and (Camera.CFrame.Position-(char:FindFirstChild("Head") and char.Head.Position or Vector3.zero)).Magnitude<1.5; if not isFP then setArmVisibility(char,true);return end; setArmVisibility(char,UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) end) end
local function stopCleanFP() if _cfpConn then _cfpConn:Disconnect();_cfpConn=nil end; setArmVisibility(LocalPlayer.Character,true) end
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.3); if _cfpEnabled then startCleanFP() end end)
local fpSec=buildSection("Rage+","Clean First Person")
fpSec:Label("Hides arms in first person. Hold RMB to show.")
fpSec:Toggle("Clean First Person",false,function(s) _cfpEnabled=s; if s then startCleanFP() else stopCleanFP() end end)

local jumpSec=buildSection("Rage+","Jump")
jumpSec:Toggle("Infinite Jump",false,function(s) MovementSettings.InfiniteJump=s;applyInfiniteJump() end)

local akSec=buildSection("Rage+","Anti Katana")
akSec:Label("Detects katana deflect and suppresses your shots.")
akSec:Toggle("Anti Katana",false,function(s) AntiKatanaSettings.Enabled=s; if s then startAntiKatana() else stopAntiKatana() end end)
akSec:Toggle("Show Indicator",true,function(s) AntiKatanaSettings.ShowIndicator=s; if _akIndicatorLbl and not s then pcall(function() _akIndicatorLbl.Visible=false end) end end)

local TINT_PRESETS={["None"]={Color3.new(1,1,1),0,0},["Pink"]={Color3.fromRGB(255,180,210),0.05,0.1},["Purple"]={Color3.fromRGB(200,160,255),0.05,0.08},["Blue"]={Color3.fromRGB(160,200,255),0,0.05},["Red"]={Color3.fromRGB(255,160,160),0.05,0.1},["Green"]={Color3.fromRGB(160,255,180),0,0.05},["Yellow"]={Color3.fromRGB(255,240,160),0.05,0.08},["Cyan"]={Color3.fromRGB(160,240,255),0,0.05},["Greyscale"]={Color3.fromRGB(200,200,200),0,0},["Night"]={Color3.fromRGB(100,120,180),-0.3,0},["Sunset"]={Color3.fromRGB(255,200,140),0.1,0.15}}
local _tintEffect=nil;local _tintEnabled=false
local function getOrMakeTint() local L=game:GetService("Lighting"); if _tintEffect and _tintEffect.Parent then return _tintEffect end; local e=L:FindFirstChild("AzyroXTint"); if e then _tintEffect=e;return _tintEffect end; local cc=Instance.new("ColorCorrectionEffect"); cc.Name="AzyroXTint"; cc.Parent=L; _tintEffect=cc; return cc end
local function applyTint(n) local p=TINT_PRESETS[n]; if not p then return end; local cc=getOrMakeTint(); if n=="None" then cc.TintColor=Color3.new(1,1,1);cc.Brightness=0;cc.Saturation=0;cc.Contrast=0 else cc.TintColor=p[1];cc.Brightness=p[2];cc.Saturation=p[3];cc.Contrast=0 end end
local function removeTint() if _tintEffect and _tintEffect.Parent then _tintEffect:Destroy();_tintEffect=nil end end
local tintPresetNames={};for k in pairs(TINT_PRESETS) do table.insert(tintPresetNames,k) end;table.sort(tintPresetNames)
local tintSec=buildSection("Rage+","World Color")
tintSec:Label("Changes the game world colour (client-side).")
tintSec:Toggle("Enable Color Tint",false,function(s) _tintEnabled=s;if not s then removeTint() end end)
tintSec:Dropdown("Color Preset",tintPresetNames,"Pink",function(sel) if _tintEnabled then applyTint(sel) end end)
local SKY_PRESETS={["Default"]=nil,["Night"]="rbxassetid://159454299",["Sunset"]="rbxassetid://159452791",["Space"]="rbxassetid://159452435",["Cloudy"]="rbxassetid://159452306",["Bluesky"]="rbxassetid://159452282"}
local _skyObj=nil;local _skyEnabled=false
local function applySky(n) local L=game:GetService("Lighting");local id=SKY_PRESETS[n]; if not id then if _skyObj and _skyObj.Parent then _skyObj:Destroy();_skyObj=nil end;return end; if not _skyObj or not _skyObj.Parent then local e=L:FindFirstChildOfClass("Sky");if e then e:Destroy() end;_skyObj=Instance.new("Sky");_skyObj.Name="azyroxSky";_skyObj.Parent=L end; for _,face in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do _skyObj[face]=id end end
local function removeSky() if _skyObj and _skyObj.Parent then _skyObj:Destroy();_skyObj=nil end end
local skyPresetNames={};for k in pairs(SKY_PRESETS) do table.insert(skyPresetNames,k) end;table.sort(skyPresetNames)
tintSec:Toggle("Custom Sky",false,function(s) _skyEnabled=s;if not s then removeSky() end end)
tintSec:Dropdown("Sky Preset",skyPresetNames,"Night",function(sel) if _skyEnabled then applySky(sel) end end)
local _glossEnabled=false;local _glossLevel=0.5;local _origSpecular=nil;local _glossSAs={};local _glossLighting=game:GetService("Lighting")
local GLOSS_PARTS={"RightUpperArm","RightLowerArm","RightHand","LeftUpperArm","LeftLowerArm","LeftHand","UpperTorso","LowerTorso","Head","Right Arm","Left Arm","Torso"}
local function addSAToChar(char) for _,e in ipairs(_glossSAs) do pcall(function() e:Destroy() end) end;_glossSAs={};if not char then return end;for _,pn in ipairs(GLOSS_PARTS) do local p=char:FindFirstChild(pn);if p and p:IsA("BasePart") then local e=p:FindFirstChildOfClass("SurfaceAppearance");if e then e:Destroy() end;local sa=Instance.new("SurfaceAppearance");sa.Roughness=math.clamp(1-_glossLevel,0,1);sa.Metalness=_glossLevel;sa.ColorMap="";sa.NormalMap="";sa.MetalnessMap="";sa.RoughnessMap="";sa.Parent=p;table.insert(_glossSAs,sa) end end end
local function removeSAs() for _,e in ipairs(_glossSAs) do pcall(function() e:Destroy() end) end;_glossSAs={} end
local function startGloss() if _origSpecular==nil then _origSpecular=_glossLighting.EnvironmentSpecularScale end;_glossLighting.EnvironmentSpecularScale=math.clamp(1+_glossLevel,0,2);addSAToChar(LocalPlayer.Character) end
local function stopGloss() removeSAs();if _origSpecular~=nil then _glossLighting.EnvironmentSpecularScale=_origSpecular;_origSpecular=nil end end
LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5);if _glossEnabled then addSAToChar(char) end end)
tintSec:Toggle("Glossy Skin",false,function(s) _glossEnabled=s;if s then startGloss() else stopGloss() end end)
tintSec:Slider("Glossiness",1,10,5,function(v) _glossLevel=v/10;if _glossEnabled then for _,sa in ipairs(_glossSAs) do pcall(function() sa.Roughness=math.clamp(1-_glossLevel,0,1);sa.Metalness=_glossLevel end) end;_glossLighting.EnvironmentSpecularScale=math.clamp(1+_glossLevel,0,2) end end)

-- AIMBOT
local aimSec=buildSection("Aimbot","Aimbot")
aimSec:Toggle("Enabled (hold RMB)",false,function(s) AimbotSettings.Enabled=s;if not s then FOVCircle.Visible=false;TargetDot.Visible=false;DotGlow1.Visible=false;DotGlow2.Visible=false end end)
aimSec:Toggle("Team Check",false,function(s) AimbotSettings.TeamCheck=s end)
aimSec:Toggle("Show FOV Circle",false,function(s) AimbotSettings.ShowFOV=s;if not s then FOVCircle.Visible=false;FOVOutline.Visible=false end end)
aimSec:Toggle("FOV Filled",false,function(s) AimbotSettings.FOVFilled=s end)
aimSec:Slider("Fill Transparency",1,10,7,function(v) AimbotSettings.FOVFillTransp=v/10 end)
aimSec:Toggle("Show Target Dot",true,function(s) AimbotSettings.ShowDot=s;if not s then TargetDot.Visible=false;DotGlow1.Visible=false;DotGlow2.Visible=false end end)
aimSec:Dropdown("Target Part",{"Head","Body","Legs"},"Head",function(sel) AimbotSettings.Target=sel end)
aimSec:Slider("FOV Radius",30,500,120,function(v) AimbotSettings.FOV=v end)
aimSec:Slider("Smoothness (1=slow 100=snap)",1,100,35,function(v) AimbotSettings.Smoothness=0.05+(v/100)*0.95 end)

local saSec=buildSection("Aimbot","Silent Aim")
saSec:Label("Redirects shots toward nearest enemy.")
saSec:Toggle("Enabled",false,function(s) SilentAimSettings.Enabled=s;if s then hookSilentAim() else unhookSilentAim() end end)
saSec:Toggle("Team Check",true,function(s) SilentAimSettings.TeamCheck=s end)
saSec:Dropdown("Hit Part",{"Head","UpperTorso","HumanoidRootPart"},"Head",function(sel) SilentAimSettings.HitPart=sel end)

-- VISUALS
local espSec=buildSection("Visuals","Player ESP")
espSec:Toggle("Name ESP",false,function(s) ESPSettings.NameESP=s end)
espSec:Toggle("Box ESP",false,function(s) ESPSettings.BoxESP=s end)
espSec:Toggle("Health Bar",false,function(s) ESPSettings.HealthBar=s end)
espSec:Toggle("Tracers",false,function(s) ESPSettings.Tracers=s end)
espSec:Toggle("Team Check",false,function(s) ESPSettings.TeamCheck=s end)

local chSec=buildSection("Visuals","Crosshair")
chSec:Toggle("Enabled",false,function(s) CrosshairSettings.Enabled=s end)
chSec:Dropdown("Style",{"Cross","Dot","Circle","Big E"},"Cross",function(sel) CrosshairSettings.Style=sel end)
chSec:Slider("Size",2,30,10,function(v) CrosshairSettings.Size=v end)
chSec:Slider("Gap",0,20,4,function(v) CrosshairSettings.Gap=v end)
chSec:Slider("Thickness",1,5,1,function(v) CrosshairSettings.Thickness=v end)
chSec:Toggle("Spin",false,function(s) CrosshairSettings.Spin=s;CrosshairSettings.Rotation=0 end)
chSec:Slider("Spin Speed",10,720,90,function(v) CrosshairSettings.SpinSpeed=v end)
chSec:Dropdown("Color",{"White","Red","Cyan","Yellow","Black"},"White",function(sel)
    local cols={White=Color3.fromRGB(255,255,255),Red=Color3.fromRGB(220,60,60),Cyan=Color3.fromRGB(60,220,220),Yellow=Color3.fromRGB(255,220,50),Black=Color3.fromRGB(0,0,0)}
    CrosshairSettings.Color=cols[sel] or Color3.new(1,1,1)
end)
chLastTime=tick(); RunService.RenderStepped:Connect(updateCrosshair)

local nameSec=buildSection("Visuals","Name Spoof")
nameSec:Toggle("Enable Name Spoof",false,function(s) RivalsSpoof.NameEnabled=s end)
nameSec:TextInput("Fake Name","Player","Enter fake name...",function(v) RivalsSpoof.FakeName=v end)
local streakSec=buildSection("Visuals","Streak Spoof")
streakSec:Toggle("Enable Streak Spoof",false,function(s) RivalsSpoof.StreakEnabled=s end)
streakSec:TextInput("Fake Streak","999","e.g. 999",function(v) RivalsSpoof.FakeStreak=v end)
local levelSec=buildSection("Visuals","Level Spoof")
levelSec:Toggle("Enable Level Spoof",false,function(s) RivalsSpoof.LevelEnabled=s end)
levelSec:TextInput("Fake Level","999","e.g. 999",function(v) RivalsSpoof.FakeLevel=v end)
local rankSec=buildSection("Visuals","Rank Spoof")
rankSec:Toggle("Enable Rank Spoof",false,function(s) RivalsSpoof.RankEnabled=s end)
rankSec:Dropdown("Fake Rank",RANK_LIST,"Gold 3",function(sel) RivalsSpoof.FakeRank=sel end)
local eloSec=buildSection("Visuals","ELO Spoof")
eloSec:Toggle("Enable ELO Spoof",false,function(s) RivalsSpoof.ELOEnabled=s end)
eloSec:TextInput("Fake ELO","9,999","e.g. 9,999",function(v) RivalsSpoof.FakeELO=v end)

-- SOUND
local sndSec=buildSection("Sound","Hit Sound")
sndSec:Label("Plays a sound when you deal damage to an enemy.")
sndSec:Toggle("Enabled",false,function(s) SoundSettings.Enabled=s;if s then startHitDetect() else stopHitDetect() end end)
local presetNames={};for k in pairs(SOUND_PRESETS) do table.insert(presetNames,k) end;table.sort(presetNames)
sndSec:Dropdown("Preset",presetNames,"Vine Boom",function(sel) if SOUND_PRESETS[sel]~="custom" then SoundSettings.SoundId=SOUND_PRESETS[sel] end;if SoundSettings.Enabled then playHitSound() end end)
sndSec:TextInput("Custom Sound ID","","e.g. 4612375452",function(val) local t=val:match("^%s*(.-)%s*$");if t~="" then local id=t:match("(%d+)$") or t;SoundSettings.SoundId="rbxassetid://"..id end end)
sndSec:Slider("Volume",0,10,5,function(v) SoundSettings.Volume=v/10;getHitSound().Volume=SoundSettings.Volume end)
sndSec:Button("Test Sound",function() playHitSound() end)

-- CONFIG
local cfgSec=buildSection("Config","Config Slots")
local CFG_DIR="azyrox_configs/";local SLOT_FILE="azyrox_slots.json"
pcall(function() if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end end)
local function serialize()
    local cfg={AimbotFOV=AimbotSettings.FOV,AimbotSmooth=AimbotSettings.Smoothness,AimbotTarget=AimbotSettings.Target,AimbotShowFOV=tostring(AimbotSettings.ShowFOV),AimbotShowDot=tostring(AimbotSettings.ShowDot),AimbotTeamCheck=tostring(AimbotSettings.TeamCheck),ESPName=tostring(ESPSettings.NameESP),ESPBox=tostring(ESPSettings.BoxESP),ESPHealth=tostring(ESPSettings.HealthBar),ESPTracers=tostring(ESPSettings.Tracers),ESPTeamCheck=tostring(ESPSettings.TeamCheck),WBOffset=UnderSettings.Offset,WB2Interval=WB2Settings.Interval,WB2VoidDepth=WB2Settings.VoidDepth,OrbitRadius=OrbitSettings.Radius,OrbitSpeed=OrbitSettings.Speed,RivalsName=RivalsSpoof.FakeName,RivalsStreak=RivalsSpoof.FakeStreak,RivalsLevel=RivalsSpoof.FakeLevel,RivalsRank=RivalsSpoof.FakeRank,RivalsELO=RivalsSpoof.FakeELO,CHEnabled=tostring(CrosshairSettings.Enabled),CHStyle=CrosshairSettings.Style,CHSize=CrosshairSettings.Size,CHGap=CrosshairSettings.Gap,CHThickness=CrosshairSettings.Thickness,CHRotation=CrosshairSettings.Rotation,CHSpin=tostring(CrosshairSettings.Spin),CHSpinSpeed=CrosshairSettings.SpinSpeed}
    local parts={}; for k,v in pairs(cfg) do local val=type(v)=="string" and ('"'..tostring(v):gsub('"','\\"')..'"') or tostring(v); table.insert(parts,'"'..k..'":'..val) end; return "{"..table.concat(parts,",").."}"
end
local function parseJSON(str) local out={}; for k,v in str:gmatch('"([^"]+)":%s*("?[^,}"]+"?)') do out[k]=v:gsub('^"',''):gsub('"$','') end; return out end
local function applyConfig(cfg)
    if cfg.AimbotFOV then AimbotSettings.FOV=tonumber(cfg.AimbotFOV) or AimbotSettings.FOV end
    if cfg.AimbotSmooth then AimbotSettings.Smoothness=tonumber(cfg.AimbotSmooth) or AimbotSettings.Smoothness end
    if cfg.AimbotTarget then AimbotSettings.Target=cfg.AimbotTarget end
    if cfg.AimbotShowFOV then AimbotSettings.ShowFOV=cfg.AimbotShowFOV=="true" end
    if cfg.AimbotShowDot then AimbotSettings.ShowDot=cfg.AimbotShowDot=="true" end
    if cfg.AimbotTeamCheck then AimbotSettings.TeamCheck=cfg.AimbotTeamCheck=="true" end
    if cfg.ESPName then ESPSettings.NameESP=cfg.ESPName=="true" end
    if cfg.ESPBox then ESPSettings.BoxESP=cfg.ESPBox=="true" end
    if cfg.ESPHealth then ESPSettings.HealthBar=cfg.ESPHealth=="true" end
    if cfg.ESPTracers then ESPSettings.Tracers=cfg.ESPTracers=="true" end
    if cfg.ESPTeamCheck then ESPSettings.TeamCheck=cfg.ESPTeamCheck=="true" end
    if cfg.WBOffset then UnderSettings.Offset=tonumber(cfg.WBOffset) or UnderSettings.Offset end
    if cfg.WB2Interval then WB2Settings.Interval=tonumber(cfg.WB2Interval) or WB2Settings.Interval end
    if cfg.WB2VoidDepth then WB2Settings.VoidDepth=tonumber(cfg.WB2VoidDepth) or WB2Settings.VoidDepth end
    if cfg.OrbitRadius then OrbitSettings.Radius=tonumber(cfg.OrbitRadius) or OrbitSettings.Radius end
    if cfg.OrbitSpeed then OrbitSettings.Speed=tonumber(cfg.OrbitSpeed) or OrbitSettings.Speed end
    if cfg.RivalsName then RivalsSpoof.FakeName=cfg.RivalsName end
    if cfg.RivalsStreak then RivalsSpoof.FakeStreak=cfg.RivalsStreak end
    if cfg.RivalsLevel then RivalsSpoof.FakeLevel=cfg.RivalsLevel end
    if cfg.RivalsRank then RivalsSpoof.FakeRank=cfg.RivalsRank end
    if cfg.RivalsELO then RivalsSpoof.FakeELO=cfg.RivalsELO end
    if cfg.CHEnabled then CrosshairSettings.Enabled=cfg.CHEnabled=="true" end
    if cfg.CHStyle then CrosshairSettings.Style=cfg.CHStyle end
    if cfg.CHSize then CrosshairSettings.Size=tonumber(cfg.CHSize) or CrosshairSettings.Size end
    if cfg.CHGap then CrosshairSettings.Gap=tonumber(cfg.CHGap) or CrosshairSettings.Gap end
    if cfg.CHThickness then CrosshairSettings.Thickness=tonumber(cfg.CHThickness) or CrosshairSettings.Thickness end
    if cfg.CHRotation then CrosshairSettings.Rotation=tonumber(cfg.CHRotation) or CrosshairSettings.Rotation end
    if cfg.CHSpin then CrosshairSettings.Spin=cfg.CHSpin=="true" end
    if cfg.CHSpinSpeed then CrosshairSettings.SpinSpeed=tonumber(cfg.CHSpinSpeed) or CrosshairSettings.SpinSpeed end
end
local function loadSlotIndex() local ok,data=pcall(readfile,SLOT_FILE); if not ok or not data or data=="" then return {} end; local list={}; for name in data:gmatch('"([^"]+)"') do table.insert(list,name) end; return list end
local function saveSlotIndex(list) local parts={}; for _,n in ipairs(list) do table.insert(parts,'"'..n:gsub('"','\\"')..'"') end; pcall(writefile,SLOT_FILE,"["..table.concat(parts,",").."]") end
local function slotFileName(name) return CFG_DIR..name:gsub('[^%w_%-]','_')..".json" end
local cfgNameInput=""; local savedSlots=loadSlotIndex(); local selectedSlot=savedSlots[1] or ""
cfgSec:TextInput("Slot Name","","e.g. rage_build",function(v) cfgNameInput=v end)
local slotPickerOptions=#savedSlots>0 and savedSlots or {"(no slots yet)"}
cfgSec:Dropdown("Saved Slots",slotPickerOptions,slotPickerOptions[1],function(sel) if sel~="(no slots yet)" then selectedSlot=sel end end)
cfgSec:Button("Save to Slot",function()
    local name=cfgNameInput~="" and cfgNameInput or selectedSlot; if not name or name=="" or name=="(no slots yet)" then return end; name=name:match("^%s*(.-)%s*$")
    pcall(function() if not isfolder(CFG_DIR) then makefolder(CFG_DIR) end end)
    local ok=pcall(writefile,slotFileName(name),serialize())
    if ok then local found=false; for _,n in ipairs(savedSlots) do if n==name then found=true;break end end; if not found then table.insert(savedSlots,name);saveSlotIndex(savedSlots) end; selectedSlot=name end
end)
cfgSec:Button("Load Selected Slot",function()
    if not selectedSlot or selectedSlot=="" or selectedSlot=="(no slots yet)" then return end
    local ok,data=pcall(readfile,slotFileName(selectedSlot)); if ok and data and data~="" then applyConfig(parseJSON(data)) end
end)
cfgSec:Button("Delete Selected Slot",function()
    if not selectedSlot or selectedSlot=="" or selectedSlot=="(no slots yet)" then return end
    pcall(delfile,slotFileName(selectedSlot)); for i,n in ipairs(savedSlots) do if n==selectedSlot then table.remove(savedSlots,i);break end end; saveSlotIndex(savedSlots); selectedSlot=savedSlots[1] or ""
end)
cfgSec:Button("Reset to Defaults",function()
    AimbotSettings.FOV=120;AimbotSettings.Smoothness=0.35;AimbotSettings.Target="Head";AimbotSettings.ShowFOV=false;AimbotSettings.ShowDot=true;AimbotSettings.TeamCheck=false
    ESPSettings.NameESP=false;ESPSettings.BoxESP=false;ESPSettings.HealthBar=false;ESPSettings.Tracers=false;ESPSettings.TeamCheck=false
    UnderSettings.Offset=-4;WB2Settings.Interval=0.5;WB2Settings.VoidDepth=-500;OrbitSettings.Radius=10;OrbitSettings.Speed=5/3
    CrosshairSettings.Enabled=false;CrosshairSettings.Style="Cross";CrosshairSettings.Size=10;CrosshairSettings.Gap=4;CrosshairSettings.Thickness=1;CrosshairSettings.Rotation=0;CrosshairSettings.Spin=false;CrosshairSettings.SpinSpeed=90
end)

local destroySec=buildSection("Config","Danger Zone")
destroySec:Button("Destroy GUI + ESP",function()
    for p in pairs(ESPObjects) do removeESP(p) end; stopFly();stopVFly();stopOrbit();stopUnder();stopSkyFly();unhookSilentAim()
    pcall(function() FOVCircle:Remove() end);pcall(function() TargetDot:Remove() end);pcall(function() DotGlow1:Remove() end);pcall(function() DotGlow2:Remove() end)
    ScreenGui:Destroy()
end)

-- Rivals Spoof loop
local spoofConn=nil
local function startRivalsSpoof()
    if spoofConn then spoofConn:Disconnect() end
    spoofConn=RunService.RenderStepped:Connect(function()
        local pg=LocalPlayer.PlayerGui; local mainGui=pg:FindFirstChild("MainGui"); if not mainGui then return end; local mainFrame=mainGui:FindFirstChild("MainFrame"); if not mainFrame then return end
        local duelIface=deepGet(mainFrame,"DuelInterfaces","DuelInterface")
        if duelIface then
            local scores=deepGet(duelIface,"Top","Scores","Teams")
            if scores then spoofTeamSlots(scores:FindFirstChild("Left")); spoofTeamSlots(scores:FindFirstChild("Right")) end
            if RivalsSpoof.RankEnabled then local eloBar=deepGet(duelIface,"FinalResults","Summary","Container","Card","BarContainer","ELOBar"); if eloBar then local lr=eloBar:FindFirstChild("LeftRank");local rr=eloBar:FindFirstChild("RightRank"); if lr then lr.Text=RivalsSpoof.FakeRank end; if rr then rr.Text=RivalsSpoof.FakeRank end end end
            if RivalsSpoof.ELOEnabled then local eloBar=deepGet(duelIface,"FinalResults","Summary","Container","Card","BarContainer","ELOBar"); if eloBar then local ce=eloBar:FindFirstChild("CurrentELO"); if ce then ce.Text=RivalsSpoof.FakeELO end end end
        end
        if RivalsSpoof.NameEnabled then
            local playerList=mainGui:FindFirstChild("PlayerList")
            if playerList then local middle=deepGet(playerList,"Container","Elements","Container","Middle","List","Container"); if middle then for _,slot in ipairs(middle:GetChildren()) do if slot.Name=="PlayerListSlot" then local title=deepGet(slot,"Player","Container","Title"); if title and title.Text==LocalPlayer.Name then title.Text=RivalsSpoof.FakeName end end end end end
            local specUsername=deepGet(mainFrame,"BottomStack","Spectate","Container","Username"); if specUsername and specUsername.Text==LocalPlayer.Name then specUsername.Text=RivalsSpoof.FakeName end
        end
    end)
end
startRivalsSpoof()

-- Activate first tab
selectTab("Rage")
