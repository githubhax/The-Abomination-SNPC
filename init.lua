include("shared.lua")
AddCSLuaFile()

-- Model
ENT.Model = {"models/NPC_Abomination.mdl"}

-- AI Settings
ENT.VJ_NPC_Class = {}
ENT.Behavior     = VJ_BEHAVIOR_AGGRESSIVE

-- Movement
ENT.MovementType      = VJ_MOVETYPE_GROUND
ENT.AnimTbl_Walk      = {ACT_WALK}
ENT.AnimTbl_Run       = {ACT_RUN}
ENT.AnimTbl_IdleStand = {ACT_IDLE}
ENT.AnimTbl_Alert     = {"anger"}
ENT.AlertAnimDuration = false

-- Health
ENT.Immune_Dissolve = true
ENT.Immune_Physics  = true
ENT.StartHealth     = 50000

-- Combat
ENT.HasMeleeAttack          = true
ENT.HasRangeAttack          = false
ENT.HasDeathAnimation       = true
ENT.HasDeathRagdoll         = false
ENT.HasMeleeAttackKnockBack = false
ENT.AnimTbl_MeleeAttack     = {"Attack", "kick"}

----------------------------------------------------------------
-- Melee Settings
----------------------------------------------------------------
ENT.MeleeAttackDistance       = 80
ENT.MeleeAttackDamageDistance = 150
ENT.MeleeAttackDamage         = 80
ENT.TimeUntilMeleeAttackDamage = 0.0833
ENT.MeleeAttackExtraTimers     = {0.3, 0.5333, 0.7833, 1.0333, 1.2167}
ENT.NextAnyAttackTime_Melee    = 0.5

----------------------------------------------------------------
-- Sound Tables
----------------------------------------------------------------
ENT.SoundTbl_BeforeMeleeAttack = {
    "attack/attack1.wav",
    "attack/attack2.wav",
    "attack/attack3.wav",
    "attack/attack4.wav"
}

ENT.SoundTbl_Alert = {
    "aware/aware1.wav"
}

ENT.IdleSoundChance   = 20   -- 20% chance
ENT.IdleSoundInterval = 2    -- min 2s between plays
ENT.SoundTbl_Idle     = {
    "idle/idle1.wav",
    "idle/idle2.wav",
    "idle/idle3.wav"
}

ENT.HasPainSounds   = true
ENT.PainSoundChance = 10
ENT.SoundTbl_Pain   = {
    "pain/pain.wav"
}

----------------------------------------------------------------
-- Footstep Settings
----------------------------------------------------------------
ENT.HasFootstepSounds         = true
ENT.DisableFootStepSoundTimer = false
ENT.FootstepSoundTimerWalk    = 0.85
ENT.FootstepSoundTimerRun     = 0.5
ENT.SoundTbl_FootStep         = {
    "step/step1.wav",
    "step/step2.wav",
    "step/step3.wav",
    "step/step4.wav"
}

ENT.DisableWandering    = false
ENT.DisableChasingEnemy = false

ENT.AnimTbl_Death          = {ACT_DIESIMPLE}
ENT.DeathAnimationMovement = true
ENT.DeathAnimationTime     = 10

----------------------------------------------------------------
-- Initialize
----------------------------------------------------------------
function ENT:CustomInitialize()
    local scale = 1.3
    self.Phase1Scale = scale
    local mins, maxs = Vector(-16,-16,0)*scale, Vector(16,16,72)*scale
    self.OriginalHullMins, self.OriginalHullMaxs = mins, maxs
    self:SetModelScale(scale, 0)
    self:SetCollisionBounds(mins, maxs)

    -- ensure melee settings apply on spawn
    self.MeleeAttackDistance       = self.MeleeAttackDistance
    self.MeleeAttackDamageDistance = self.MeleeAttackDamageDistance
    self.MeleeAttackDamage         = self.MeleeAttackDamage
    self.TimeUntilMeleeAttackDamage = self.TimeUntilMeleeAttackDamage
    self.MeleeAttackExtraTimers     = self.MeleeAttackExtraTimers
    self.NextAnyAttackTime_Melee    = self.NextAnyAttackTime_Melee
end

----------------------------------------------------------------
-- Death Screen Shake
----------------------------------------------------------------
function ENT:CustomDeathAnimationCode(dmginfo, hitgroup)
    timer.Simple(1.35, function()
        if IsValid(self) then
            util.ScreenShake(self:GetPos(), 100, 150, 2, 1000)
        end
    end)
end

----------------------------------------------------------------
-- Footstep Screen Shake
----------------------------------------------------------------
function ENT:OnFootstepSound(moveType, sdFile)
    util.ScreenShake(self:GetPos(), 5, 2, 0.5, 1000)
end

----------------------------------------------------------------
-- Melee Attack Hook
----------------------------------------------------------------
function ENT:OnMeleeAttack(status, enemy)
    if status ~= "Init" or not IsValid(enemy) then return end
    local seq = string.lower(self:GetSequenceName(self:GetSequence()))

    if seq == "attack" then
        -- multi-hit punch combo
        local extra = {0.3,0.5333,0.7833,1.0333,1.2167}
        self.TimeUntilMeleeAttackDamage = 0.0833
        self.MeleeAttackExtraTimers     = extra
        if self.HasSwappedModel then
            self.MeleeAttackDamage       = 50000
            self.NextAnyAttackTime_Melee = 1.0
        else
            self.MeleeAttackDamage       = 80
            self.NextAnyAttackTime_Melee = 0.5
        end

    elseif seq == "kick" then
        -- single-hit kick with knockback
        local delay = self.HasSwappedModel and 0.0833 or 1.16
        self.TimeUntilMeleeAttackDamage = delay
        self.MeleeAttackExtraTimers     = {}
        if self.HasSwappedModel then
            self.MeleeAttackDamage       = 50000
            self.NextAnyAttackTime_Melee = 1.2
        else
            self.MeleeAttackDamage       = 1000
            self.NextAnyAttackTime_Melee = 0.8
        end
        -- apply knockback on kick
        timer.Simple(delay, function()
            if not IsValid(self) or not IsValid(enemy) then return end
            local push = -self:GetForward() * 200 + Vector(0,0,100)
            -- allow airborne
            if enemy:IsOnGround() then enemy:SetGroundEntity(NULL) end
            enemy:SetVelocity(push)
            -- fallback local velocity
            if enemy.SetLocalVelocity then enemy:SetLocalVelocity(push) end
        end)
    end
end

----------------------------------------------------------------
-- Phase-2 Transform
----------------------------------------------------------------
function ENT:PhaseTwoTransform()
    self:SetModelScale(10, 0)
    self:SetCollisionBounds(self.OriginalHullMins, self.OriginalHullMaxs)
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self.MeleeAttackDistance       = 400
    self.MeleeAttackDamageDistance = 1200
    self:SetHealth(50000000)
    self.HasSwappedModel = true
    local c = self.OriginalColor or Color(255,255,255,255)
    self:SetColor(Color(c.r, math.min(c.g+50,255), c.b, c.a))
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
end

----------------------------------------------------------------
-- Damage Hook for Transform
----------------------------------------------------------------
function ENT:OnDamaged(dmginfo, hitgroup, status)
    if status == "PreDamage" and not self.HasSwappedModel then
        if self:Health() - dmginfo:GetDamage() <= 30000 then
            self:PhaseTwoTransform()
            return true
        end
    end
end

----------------------------------------------------------------
-- Idle & Alert Sounds
----------------------------------------------------------------
function ENT:CustomOnThink()
    local ct = CurTime()
    if self:GetEnemy() and ct >= (self.NextIdleSound or 0) then
        if math.random(1,100) <= self.IdleSoundChance then
            local pool = table.Copy(self.SoundTbl_Idle)
            for _,v in ipairs(self.SoundTbl_Alert) do table.insert(pool, v) end
            self:EmitSound(table.Random(pool), 75, 100)
            self.NextIdleSound = ct + self.IdleSoundInterval
        end
    end
end