--Do not copy anything without permission, if you copy the file you will respond for plagiarism
--@ Copyright: Jace Nicky.

IncludeFile("Lib\\SDK.lua")

class "Jhin"

local ScriptXan = 0.1
local NameCreat = "Jace Nicky"


function OnLoad()
    if myHero.CharName ~= "Jhin" then return end
    __PrintTextGame("<b><font color=\"#00FF00\">Champion:</font></b> " ..myHero.CharName.. "<b><font color=\"#FF0000\"> Good Game!</font></b>")
    __PrintTextGame("<b><font color=\"#00FF00\">Jhin, v</font></b> " ..ScriptXan)
    __PrintTextGame("<b><font color=\"#00FF00\">By: </font></b> " ..NameCreat)
    Jhin:ADC_()
end

function Jhin:ADC_()
    SetLuaCombo(true)
    --SetLuaLaneClear(true)

    self.recharging = false
    self.GoodBay = nil
    self.RActive = false
    self.MarkedEne = nil
    self.RStack = 0
    self.SpellStack = 0 
    self.DelayR = 0
    self.FirstSpellStart = Vector(0,0,0)
    self.FirstSpellEnd = Vector(0,0,0)

    --Spells 
    self.Q = Spell({Slot = 0, SpellType = Enum.SpellType.Targetted, Range = 550})
    self.W = Spell({Slot = 1, SpellType = Enum.SpellType.SkillShot, Range = 3000, SkillShotType = Enum.SkillShotType.Line, Collision = false, Width = 160, Delay = 0.25, Speed = 1600})
    self.E = Spell({Slot = 2, SpellType = Enum.SpellType.SkillShot, Range = 750, SkillShotType = Enum.SkillShotType.Circle, Collision = false, Width = 160, Delay = 0.25, Speed = 1600})
    self.R = Spell({Slot = 3, SpellType = Enum.SpellType.SkillShot, Range = 3500, SkillShotType = Enum.SkillShotType.Line, Collision = false, Width = 160, Delay = 0.25, Speed = 1600})

    AddEvent(Enum.Event.OnTick, function(...) self:OnTick(...) end)
    AddEvent(Enum.Event.OnProcessSpell, function(...) self:OnProcessSpell(...) end)
    AddEvent(Enum.Event.OnDraw, function(...) self:OnDraw(...) end)
    AddEvent(Enum.Event.OnUpdateBuff, function(...) self:OnUpdateBuff(...) end)
    AddEvent(Enum.Event.OnRemoveBuff, function(...) self:OnRemoveBuff(...) end)
    AddEvent(Enum.Event.OnDrawMenu, function(...) self:OnDrawMenu(...) end)
    AddEvent(Enum.Event.OnVision, function(...) self:OnVision(...) end)  
    --
    Orbwalker:RegisterPostAttackCallback(function(...) self:OnPostAttack(...) end) 

    self:JhinMenu()
end 

function Jhin:OnTick()
    if IsDead(myHero.Addr) or myHero.IsRecall or IsTyping() or not IsRiotOnTop() then return end

    if GetSpellNameByIndex(myHero.Addr, _R) == "JhinRShot" then
        self.RActive = true
    else
        self.RActive = false
    end
    
    if GetKeyPress(self.ActR) > 0 then
        if self.RMode == 0 then
            self:AtiveR()
        elseif self.RMode == 1 then
            self:AtiveR2()
        end 
    end

    if self.RMode == 0 then
        self:CanR()
    elseif self.RMode == 1 then
        self:CanR2()
    end

    if self.WMode == 0 then
        self:CanWNotMarked()
    elseif self.WMode == 1 then
        self:CanWMarked()
    end

    if self.Focus then
        self:AutoFocusW()
    end 

    if not self.AA then
        self:CastQNotAttac()
    end 

    --Stack Passive
    if GetSpellLevel(myHero.Addr, _R) == 1 then
        self.RStack = 4 
    elseif GetSpellLevel(myHero.Addr, _R) == 2 then
        self.RStack = 4
    elseif GetSpellLevel(myHero.Addr, _R) == 3 then
        self.RStack = 4
    else
        self.RStack = 0
    end
end 

function Jhin:OnPostAttack()
    local TargetQ = GetTargetSelector(self.Q.Range, 1)
    target = GetAIHero(TargetQ)
    if TargetQ ~= 0 and self.AA then
        if IsValidTarget(target, self.Q.Range) then
            CastSpellTarget(target.Addr, _Q)
        end 
    end 
end 

function Jhin:OnVision(unit, state)
    local TargetR = GetTargetSelector(self.R.Range, 1)
    target = GetAIHero(TargetR)
    if state ~= false then 
        if self.RActive then
            if unit.NetworkId == target.NetworkId and self:InRCone(target) then
                CastSpellToPos(unit.x, unit.z, _R)
            end 
        end    
    end 
end 

function Jhin:OnProcessSpell(unit, spell)
    if unit.IsMe and spell.Name == "JhinR" then
        self.FirstSpellStart = Vector(spell.SourcePos_x, spell.SourcePos_y, spell.SourcePos_z)
        self.FirstSpellEnd = Vector(spell.DestPos_x, spell.DestPos_y, spell.DestPos_z)
    end 
    if unit.IsMe and spell.Name == "JhinRShot" then
        if self.SpellStack > 0 then
            self.SpellStack = self.SpellStack - 1
        end 
    end 
end  

function Jhin:OnUpdateBuff(source, unit, buff, stacks)
    if unit.IsMe and buff.Name == "JhinRShot" then
        self.RActive = true
        SetLuaMoveOnly(true)
        SetLuaBasicAttackOnly(true)
        SetEvade(true)
        self.SpellStack = self.RStack
    end
    if unit.IsMe and buff.Name == "JhinPassiveReload" then
        self.recharging = true
        SetLuaBasicAttackOnly(true)
    end 
    if unit.IsMe and buff.Name == "jhinpassiveattackbuff" then
        self.GoodBay = myHero    
    end 
    if unit.IsEnemy and buff.Name == "jhinespotteddebuff" then
        self.MarkedEne = unit.IsEnemy
    end 
end

function Jhin:OnRemoveBuff(unit, buff)
    if unit.IsMe and buff.Name == "JhinRShot" then
        self.RActive = false
        SetLuaMoveOnly(false)
        SetLuaBasicAttackOnly(false)
        SetEvade(false)
        self.SpellStack = 0
    end 
    if unit.IsMe and buff.Name == "JhinPassiveReload" then
        self.recharging = false
        SetLuaBasicAttackOnly(false)
    end 
    if myHero.IsMe and buff.Name == "jhinpassiveattackbuff" then
        self.GoodBay = nil    
    end 
    if unit.IsEnemy and buff.Name == "jhinespotteddebuff" then
        self.MarkedEne = nil
    end 
end

function Jhin:OnDraw()
    for i,hero in pairs(self:GetEnemies(self.R.Range)) do
		if IsValidTarget(hero, self.R.Range) and  self.CheckR then
            target = GetAIHero(hero)
            local mousePos = Vector(GetMousePos())
            if (self.R:IsReady() or self.RActive) and IsValidTarget(target, self.R.Range) and self:OfcRDamage(target) > target.HP then
                local pos = Vector(target.x, target.y, target.z)
                DrawCircleGame(pos.x , pos.y, pos.z, 150, Lua_ARGB(255, 255, 0, 0))

				local pos = Vector(target.x, target.y, target.z)
                local x, y, z = pos.x, pos.y, pos.z
                local p1X, p1Y = WorldToScreen(x, y, z)
                local p2X, p2Y = WorldToScreen(myHero.x, myHero.y, myHero.z)
                DrawLineD3DX(p1X, p1Y, p2X, p2Y, 2, Lua_ARGB(255, 255, 0, 0)) 
                
                local a,b = WorldToScreen(target.x, target.y, target.z)
				DrawTextD3DX(a, b, "KILL [R]"..target.CharName, Lua_ARGB(255, 255, 255, 10))
			end
		end
    end
end 

function Jhin:CanTestW()
    local TargetR = GetTargetSelector(self.R.Range, 1)
	if TargetR ~= nil then
        target = GetAIHero(TargetR)
        if self.RActive  and self:InRCone(target) then
            local CastPosition, HitChance, Position = self:RLinePreCore(target)
            if HitChance >= 5 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _R) 
            end 
        end 
    end 
end 

function Jhin:AtiveR()
    local TargetR = GetTargetSelector(self.R.Range, 1)
	if TargetR ~= 0 then
        target = GetAIHero(TargetR)
        if IsValidTarget(target, self.R.Range) then
            local CastPosition, HitChance, Position = self:RConePreCore(target)
            if HitChance >= 5 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _R)
            end
        end 
    end 
end 

function Jhin:AtiveR2()
    local TargetR = GetTargetSelector(self.R.Range, 1)
	if TargetR ~= 0 then
        target = GetAIHero(TargetR)
        if IsValidTarget(target, self.R.Range) and self:OfcRDamage(target) > target.HP then
            local CastPosition, HitChance, Position = self:RConePreCore(target)
            if HitChance >= 5 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _R)
            end 
        end 
    end 
end 

function Jhin:CanR()
    local TargetR = GetTargetSelector(self.R.Range, 1)
	if TargetR ~= nil then
        target = GetAIHero(TargetR)
        if self.RActive and IsValidTarget(target, self.R.Range) and self:InRCone(target) then
            local CastPosition, HitChance, Position = self:RLinePreCore(target)
            if HitChance >= 5 and GetTimeGame() - self.DelayR >= 0.25 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _R)
                self.DelayR = GetTimeGame()
            end 
        end 
    end 
end 

function Jhin:CanR2()
    local TargetR = GetTargetSelector(self.R.Range, 1)
	if TargetR ~= nil then
        target = GetAIHero(TargetR)
        if self.RActive and IsValidTarget(target, self.R.Range) and self:InRCone(target) and self:OfcRDamage(target) > target.HP then
            local CastPosition, HitChance, Position = self:RLinePreCore(target)
            if HitChance >= 5 and GetTimeGame() - self.DelayR >= 0.25 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _R)
                self.DelayR = GetTimeGame()
            elseif self.RActive and IsValidTarget(target, self.R.Range) and self:InRCone(target) then
                if HitChance >= 5 and GetTimeGame() - self.DelayR >= 0.25 then
                    CastSpellToPos(CastPosition.x, CastPosition.z, _R)
                    self.DelayR = GetTimeGame()
                end 
            end 
        end 
    end 
end 

function Jhin:CanWNotMarked()
    local TargetR = GetTargetSelector(self.W.Range, 1)
	if TargetR ~= nil and GetOrbMode() == 1 then
        target = GetAIHero(TargetR)
        if not self.RActive and IsValidTarget(target, self.W.Range) then
            local CastPosition, HitChance, Position = self:WLinePreCore(target)
            if HitChance >= 5 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _W)
            end 
        end 
    end 
end 

function Jhin:CanWMarked()
    local TargetR = GetTargetSelector(self.W.Range, 1)
	if TargetR ~= nil and GetOrbMode() == 1 then
        target = GetAIHero(TargetR)
        if not self.RActive and IsValidTarget(target, self.W.Range) and self.MarkedEne then
            local CastPosition, HitChance, Position = self:WLinePreCore(target)
            if HitChance >= 5 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _W)
            end 
        end 
    end 
end 

function Jhin:AutoFocusW()
    local TargetR = GetTargetSelector(self.W.Range, 1)
	if TargetR ~= nil and self:ManaPercent(myHero) >= self.Mana1 then
        target = GetAIHero(TargetR)
        if not self.RActive and IsValidTarget(target, self.W.Range) and self.MarkedEne then
            local CastPosition, HitChance, Position = self:WLinePreCore(target)
            if HitChance >= 5 then
                CastSpellToPos(CastPosition.x, CastPosition.z, _W)
            end 
        end 
    end 
end 

function Jhin:CastQNotAttac()
    local TargetQ = GetTargetSelector(self.Q.Range, 1)
    target = GetAIHero(TargetQ)
    if TargetQ ~= 0 and GetOrbMode() == 1 then
        if IsValidTarget(target, self.Q.Range) then
            CastSpellTarget(target.Addr, _Q)
        end 
    end 
end 
-----------------
--Orthes--
-----------------

function Jhin:InRCone(Position)
	local range = 3500
	local angle = 70 * math.pi / 180
	local end2 = self.FirstSpellEnd - self.FirstSpellStart
	local edge1 = self:Rotated(end2, -angle / 2)
	local edge2 = self:Rotated(edge1, angle)

	local point = Position - self.FirstSpellStart
	if GetDistanceSqr(point, Vector(0,0,0)) < range * range and self:CrossProduct(edge1, point) > 0 and self:CrossProduct(point, edge2) > 0 then
		return true
	end
	return false
end

function Jhin:Rotated(v, angle)
	local c = math.cos(angle)
	local s = math.sin(angle)
	return Vector(v.x * c - v.z * s, 0, v.z * c + v.x * s)
end

function Jhin:CrossProduct(p1, p2)
	return (p2.z * p1.x - p2.x * p1.z)
end

function Jhin:IsMarked(target)
    return target.IsEnemy and target.HasBuff("jhinespotteddebuff")
end

-----------------
--Prediciton--
-----------------
function Jhin:WLinePreCore(target)
	local castPosX, castPosZ, unitPosX, unitPosZ, hitChance, _aoeTargetsHitCount = GetPredictionCore(target.Addr, 0, 0.5, 50, self.W.Range, 1200, myHero.x, myHero.z, false, false, 1, 1, 5, 5, 5, 5)
	if target ~= nil then
		 CastPosition = Vector(castPosX, target.y, castPosZ)
		 HitChance = hitChance
		 Position = Vector(unitPosX, target.y, unitPosZ)
		 return CastPosition, HitChance, Position
	end
	return nil , 0 , nil
end

function Jhin:RConePreCore(target)
	local castPosX, castPosZ, unitPosX, unitPosZ, hitChance, _aoeTargetsHitCount = GetPredictionCore(target.Addr, 2, self.R.delay, 75, self.R.Range, self.R.speed, myHero.x, myHero.z, false, false, 1, 5, 5, 5, 5, 5)
	if target ~= nil then
		 CastPosition = Vector(castPosX, target.y, castPosZ)
		 HitChance = hitChance
		 Position = Vector(unitPosX, target.y, unitPosZ)
		 AOE = _aoeTargetsHitCount
		 return CastPosition, HitChance, Position, AOE
	end
	return nil , 0 , nil, 0
end

function Jhin:RLinePreCore(target)
	local castPosX, castPosZ, unitPosX, unitPosZ, hitChance, _aoeTargetsHitCount = GetPredictionCore(target.Addr, 0, 0.25, 90, self.R.Range, 2000, myHero.x, myHero.z, false, false, 1, 0, 5, 5, 5, 5)
	if target ~= nil then
		 CastPosition = Vector(castPosX, target.y, castPosZ)
		 HitChance = hitChance
		 Position = Vector(unitPosX, target.y, unitPosZ)
		 return CastPosition, HitChance, Position
	end
	return nil , 0 , nil
end

-----------------
--Damage API--
-----------------
function Jhin:OfcRDamage(target) -- Ty Nechrito <3 THAKS <3 
    local aa = myHero.TotalDmg
    local dmg = aa
  
    if self.R:IsReady() then
        dmg = dmg + self:GetRDamage(target) * self.RStack
    end

    dmg = self:RealDamage(target, dmg)
    return dmg
end


function Jhin:GetRDamage(target)
    if target ~= 0 and CanCast(_R) then
		local Damage = 0
		local DamageAP = {50, 125, 200}

        if self.R:IsReady() then
			Damage = (DamageAP[myHero.LevelSpell(_R)] + 0.20 * myHero.BonusDmg)
        end
		return myHero.CalcDamage(target.Addr, Damage)
	end
	return 0
end

function Jhin:RealDamage(target, damage)
    if target.HasBuff("KindredRNoDeathBuff") or target.HasBuff("JudicatorIntervention") or target.HasBuff("FioraW") or target.HasBuff("ShroudofDarkness")  or target.HasBuff("SivirShield") then
        return 0  
    end
    local pbuff = GetBuff(GetBuffByName(target, "UndyingRage"))
    if target.HasBuff("UndyingRage") and pbuff.EndT > GetTimeGame() + 0.3  then
        return 0
    end
    local pbuff2 = GetBuff(GetBuffByName(target, "ChronoShift"))
    if target.HasBuff("ChronoShift") and pbuff2.EndT > GetTimeGame() + 0.3 then
        return 0
    end
    if myHero.HasBuff("SummonerExhaust") then
        damage = damage * 0.6;
    end
    if target.HasBuff("BlitzcrankManaBarrierCD") and target.HasBuff("ManaBarrier") then
        damage = damage - target.MP / 2
    end
    if target.HasBuff("GarenW") then
        damage = damage * 0.6;
    end
    return damage
end

function Jhin:GetHeroes()
	SearchAllChamp()
	local t = pObjChamp
	return t
end

function Jhin:GetEnemies(range)
    local t = {}
    local h = self:GetHeroes()
    for k, v in pairs(h) do
        if v ~= 0 then
            local hero = GetAIHero(v)
            if hero.IsEnemy and hero.IsValid and hero.Type == 0 and (not range or range > GetDistance(hero)) then
                table.insert(t, hero)
            end 
        end 
    end
    return t
end

function Jhin:MenuBool(stringKey, bool)
	return ReadIniBoolean(self.menu, stringKey, bool)
end

function Jhin:MenuSliderInt(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end

function Jhin:MenuSliderFloat(stringKey, valueDefault)
	return ReadIniFloat(self.menu, stringKey, valueDefault)
end

function Jhin:MenuComboBox(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end

function Jhin:MenuKeyBinding(stringKey, valueDefault)
	return ReadIniInteger(self.menu, stringKey, valueDefault)
end

function Jhin:JhinMenu()
    self.menu = "Jhin"
    --Combo [[ Jhin ]]
    self.CQ = self:MenuBool("Combo Q", true)
    self.AA = self:MenuBool("AA + Q", true)
    self.CW = self:MenuBool("Combo W", true)
    self.CE = self:MenuBool("Combo E", true)
    self.CR = self:MenuBool("Combo R", true)

    self.AAQ = self:MenuBool("Auto Q", true)
    self.LogicR = self:MenuBool("Logic R", true)

    self.UnTurret = self:MenuBool("Turret", true)
    --self.AntiGapcloserE = self:MenuBool("AntiGapcloser [E]", true)
    self.Focus = self:MenuBool("Focus Marked", true)
    self.Evade_R = self:MenuBool("Dont Dodge When R Is Active",true)

    self.Danger = self:MenuSliderInt("Danger", 4)
	self.MaxRangeW = self:MenuSliderInt("Max R range", 2900)
	self.MinRangeW = self:MenuSliderInt("Min R range", 500)
    self.CancelR = self:MenuBool("Cancel  [R]", true)

    self.ModeE = self:MenuComboBox("Mode [W] Spell", 1)
    self.StackSPellQ = self:MenuBool("StackQ", false)

     --Lane
     self.LQ = self:MenuBool("Lane Q", true)
     self.LW = self:MenuBool("Lane W", true)
     self.LE = self:MenuBool("Lane E", true)
     self.LQ3 = self:MenuBool("Lane Q3", true)

    --Draws [[ Jhin ]]
    self.CheckR = self:MenuBool("Check R", true)
    self.DQ = self:MenuBool("Draw Q", true)
    self.DW = self:MenuBool("Draw W", true)
    self.DE = self:MenuBool("Draw E", true)
    self.DR = self:MenuBool("Draw R", true)

    self.ComboMode = self:MenuComboBox("Combo[ J ]", 2)
    self.WMode = self:MenuComboBox("Mode [W] [ J ]", 1)
    self.RMode = self:MenuComboBox("Mode Combo R", 1)
    self.Mana1 = self:MenuSliderInt("Mana", 25)
    --Key
    self.Combo = self:MenuKeyBinding("Combo", 32)
    self.LaneClear = self:MenuKeyBinding("Lane Clear", 86)
    self.Last_Hit = self:MenuKeyBinding("Last Hit", 88)
    self.ActR = self:MenuKeyBinding("Flee", 84)

end

function Jhin:OnDrawMenu()
	if not Menu_Begin(self.menu) then return end
        if (Menu_Begin("Combo")) then
            Menu_Text("--Combo [Q]--")
            self.CQ = Menu_Bool("Use Q", self.CQ, self.menu)
            self.AA = Menu_Bool("AA + Q", self.AA, self.menu)
            Menu_Separator()
            Menu_Text("--Combo [W]--")
            self.CW = Menu_Bool("Use W", self.CW, self.menu)
            self.WMode = Menu_ComboBox("W [Mode] Logic", self.WMode, "Smart\0Marked\0\0", self.menu)
            self.Focus = Menu_Bool("Auto Focus Marked [Jhin W]", self.Focus, self.menu)
            self.Mana1 = Menu_SliderInt("Settings Mana [Auto Focus Marked] % >", self.Mana1, 0, 100, self.menu)
            Menu_Separator()
            Menu_Text("--Combo [E]--")
            self.CE = Menu_Bool("Use E", self.CE, self.menu)
            --self.AntiGapcloserE = Menu_Bool("AntiGapcloser [E]", self.AntiGapcloserE, self.menu)
            Menu_Separator()
            Menu_Text("--Combo [R]--")
            self.CR = Menu_Bool("Use R", self.CR, self.menu)
            self.ActR = Menu_KeyBinding("Key Ult [R]", self.ActR, self.menu)
            self.LogicR = Menu_Bool("Logic [R] [VisionPos]", self.LogicR, self.menu)
            Menu_Separator()
            Menu_Text("--Misc--")
            self.CancelR = Menu_Bool("Cancel [R]", self.CancelR, self.menu)
            self.Evade_R = Menu_Bool("Dont Dodge When R Is Active", self.Evade_R,self.menu)
            self.RMode = Menu_ComboBox("Mode Combo R", self.RMode, "Always\0Damage\0\0\0", self.menu)
			Menu_End()
        end
        if (Menu_Begin("Draws")) then
            self.CheckR = Menu_Bool("Check [R] [KillSteal]", self.CheckR, self.menu)
			Menu_End()
        end
	Menu_End()
end

function Jhin:ManaPercent(target)
    return target.MP/target.MaxMP * 100
end