pangolier_q_modifier = class({})

require("game_time")

function pangolier_q_modifier:OnCreated(kv)
  if IsServer() then
    local parent = self:GetParent()
    self.end_point = GetGroundPosition(Vector(kv.x, kv.y, 0), parent)
    self.start_point = GetGroundPosition(parent:GetAbsOrigin(), parent)
    self.duration = kv.duration
    self.start_time = GameTime:GetTime()
    self.end_time = self.start_time + self.duration
    self.totalDistance = (self.end_point - self.start_point):Length2D()
    self.direction = self.end_point - self.start_point
    self.direction = self.direction:Normalized()
    self.zDiff = self.end_point.z - self.start_point.z

    --face unit forward
    local forward = self.direction
    forward.z = 0
    parent:SetForwardVector(forward)

    EmitSoundOn("Hero_Pangolier.TailThump.Cast", parent)
    self:StartIntervalThink(0.03)
	end
end

function pangolier_q_modifier:OnIntervalThink()
  if IsServer() then
    local now = GameTime:GetTime()
    if now >= self.end_time then
      return -1
    end

    local parent = self:GetParent()
    
    local timePassed = now - self.start_time
    local percentCompleted = timePassed / self.duration
    local dist = self.totalDistance * percentCompleted
    local nextPos = self.start_point + self.direction * dist
    
    local zOffset = 250
    local zBonus = 0

    local transitionTime = 0.1
    local timeUntilEnd = self.end_time - now
    local multiplier = 1
    if timePassed < transitionTime then
      --transition up
      multiplier = timePassed/transitionTime
    elseif timeUntilEnd < transitionTime then --ending
      --transision down
      multiplier = timeUntilEnd/transitionTime
    else
      local upTime = self.duration - (2*transitionTime)
      local upTimePercent = (timeUntilEnd - transitionTime)/upTime
      local a = 1 - math.abs(upTimePercent - 0.5) * 2 --value from 0-1 from min to max height in up time (max = 1)
      local maxBonusZOffset = 50

      zBonus = maxBonusZOffset * a
      multiplier = 1
    end

    nextPos.z = nextPos.z + zOffset * multiplier + zBonus --animation
    nextPos.z = nextPos.z + self.zDiff * percentCompleted --z different heights at start and end

    parent:SetOrigin(nextPos) 
    
    return 0.03
	end
end

function pangolier_q_modifier:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()
    
    if parent:IsAlive() then
      FindClearSpaceForUnit(parent, self.end_point, true)
      local radius = self:GetAbility():GetAOERadius()

      local units = FindUnitsInRadius(
        parent:GetTeam(),
        parent:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
      )

      --apply damage
      for _,unit in pairs(units) do
        ApplyDamage({
          victim = unit,
          attacker = parent,
          damage = 2,
          damage_type = DAMAGE_TYPE_PURE,
          ability = self
        })
      end

      EmitSoundOn("Hero_Pangolier.TailThump", parent)
      ParticleManager:CreateParticle(
        "particles/econ/items/pangolier/pangolier_ti8_immortal/pangolier_ti8_immortal_shield_crash.vpcf",
        PATTACH_ABSORIGIN,
        parent
      )
    else
      FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), false)
    end
  end
end

function pangolier_q_modifier:CheckState()
	local state = {
    [MODIFIER_STATE_STUNNED] = true
	}

	return state
end

function pangolier_q_modifier:DeclareFunctions()
	local funcs = {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}

	return funcs
end

function pangolier_q_modifier:GetOverrideAnimation( params )
	return ACT_DOTA_FLAIL
end
