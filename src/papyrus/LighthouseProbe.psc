Scriptname LighthouseProbe extends Quest
{ Lighthouse API probe — validates that Lighthouse Papyrus Extender
  functions are callable and return expected types/values.
  Logs everything to User/LighthouseProbe.0.log
  Run once, check log, then remove from ESP. }

String LOG_NAME = "LighthouseProbe" Const

Int TIMER_PROBE = 0 Const
Int TIMER_REPEAT = 1 Const

; Probe runs every 2 seconds for live data validation
Float PROBE_INTERVAL = 2.0 Const

Event OnInit()
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "========================================")
    Debug.TraceUser(LOG_NAME, "=== LighthouseProbe OnInit ===")
    Debug.TraceUser(LOG_NAME, "========================================")

    ; Check Lighthouse version first
    int[] ver = Lighthouse.GetLighthouseVersion()
    if ver
        Debug.TraceUser(LOG_NAME, "Lighthouse version: " + ver[0] + "." + ver[1] + "." + ver[2])
    else
        Debug.TraceUser(LOG_NAME, "ERROR: GetLighthouseVersion returned None!")
    endif

    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    StartTimer(4.0, TIMER_PROBE)
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
    Debug.OpenUserLog(LOG_NAME)
    Debug.TraceUser(LOG_NAME, "=== OnPlayerLoadGame — restarting probe ===")
    StartTimer(4.0, TIMER_PROBE)
EndEvent

Event OnTimer(Int aiTimerID)
    if aiTimerID == TIMER_PROBE
        RunProbe()
        ; Start repeating probe for live data
        StartTimer(PROBE_INTERVAL, TIMER_REPEAT)
    elseif aiTimerID == TIMER_REPEAT
        RunProbe()
        StartTimer(PROBE_INTERVAL, TIMER_REPEAT)
    endif
EndEvent

Function RunProbe()
    Actor player = Game.GetPlayer()

    Debug.TraceUser(LOG_NAME, "--- PROBE TICK ---")

    ; === WEAPON / AMMO (the big ones) ===
    int magCur = Lighthouse.GetWeaponAmmoCount(player)
    Debug.TraceUser(LOG_NAME, "[AMMO] magCurrent = " + magCur)

    int magCap = Lighthouse.GetWeaponAmmoCapacity(player)
    Debug.TraceUser(LOG_NAME, "[AMMO] magCapacity = " + magCap)

    int magCount = Lighthouse.GetWeaponMagCount(player, true)
    Debug.TraceUser(LOG_NAME, "[AMMO] spareMags = " + magCount)

    Ammo ammoType = Lighthouse.GetWeaponAmmoType(player)
    if ammoType
        int reserve = player.GetItemCount(ammoType as Form)
        Debug.TraceUser(LOG_NAME, "[AMMO] ammoType = " + ammoType.GetName() + ", reserve = " + reserve)
    else
        Debug.TraceUser(LOG_NAME, "[AMMO] ammoType = None (melee/unarmed?)")
    endif

    int gunState = Lighthouse.GetActorGunState(player)
    Debug.TraceUser(LOG_NAME, "[WEAPON] gunState = " + gunState)

    ; === F4SE: WEAPON FLAGS (auto/semi/bolt) ===
    ; NOTE: InstanceData properties can't be accessed on the type directly,
    ; so we use raw int values from InstanceData.psc
    int FLAG_AUTOMATIC          = 0x0004000
    int FLAG_BOLT_ACTION        = 0x0400000
    int FLAG_REPEATABLE_SINGLE  = 0x0000800
    int FLAG_HAS_SCOPE          = 0x0001000

    Weapon equippedWeapon = player.GetEquippedWeapon(0)
    if equippedWeapon
        Debug.TraceUser(LOG_NAME, "[WEAPON] equipped = " + equippedWeapon.GetName())

        InstanceData:Owner inst = player.GetInstanceOwner(0)
        bool isAuto = InstanceData.GetFlag(inst, FLAG_AUTOMATIC)
        bool isBolt = InstanceData.GetFlag(inst, FLAG_BOLT_ACTION)
        bool isSemi = InstanceData.GetFlag(inst, FLAG_REPEATABLE_SINGLE)
        bool hasScope = InstanceData.GetFlag(inst, FLAG_HAS_SCOPE)
        int dmg = InstanceData.GetAttackDamage(inst)
        float maxRange = InstanceData.GetMaxRange(inst)

        Debug.TraceUser(LOG_NAME, "[FLAGS] auto=" + isAuto + " bolt=" + isBolt + " semi=" + isSemi + " scope=" + hasScope)
        Debug.TraceUser(LOG_NAME, "[STATS] damage=" + dmg + " maxRange=" + maxRange)
    else
        Debug.TraceUser(LOG_NAME, "[WEAPON] No weapon equipped")
    endif

    ; === DETECTION / COMBAT ===
    bool detected = Lighthouse.IsPlayerDetectedByHostile()
    Debug.TraceUser(LOG_NAME, "[STEALTH] detectedByHostile = " + detected)

    bool hostilesNear = Lighthouse.AreHostileActorsInRange(player, 2000)
    Debug.TraceUser(LOG_NAME, "[COMBAT] hostilesInRange(2000) = " + hostilesNear)

    Actor[] hostiles = Lighthouse.GetActorsHostileToActor(player, 3000, false)
    int hostileCount = 0
    if hostiles
        hostileCount = hostiles.Length
    endif
    Debug.TraceUser(LOG_NAME, "[COMBAT] hostileCount(3000) = " + hostileCount)

    bool takingDmg = Lighthouse.IsTakingHealthDamage(player)
    bool takingRad = Lighthouse.IsTakingRadDamage(player)
    Debug.TraceUser(LOG_NAME, "[DAMAGE] healthDmg=" + takingDmg + " radDmg=" + takingRad)

    ; === PLAYER STATE ===
    float heading = Lighthouse.GetPlayerHeading()
    Debug.TraceUser(LOG_NAME, "[NAV] heading = " + heading)

    float encRate = Lighthouse.GetEncumbranceRate(player)
    Debug.TraceUser(LOG_NAME, "[CARRY] encumbranceRate = " + encRate)

    int followers = Lighthouse.GetFollowerCount()
    Debug.TraceUser(LOG_NAME, "[SQUAD] followerCount = " + followers)

    float vatsCrit = Lighthouse.GetVATSCriticalCharge()
    Debug.TraceUser(LOG_NAME, "[VATS] critCharge = " + vatsCrit)

    bool underwater = Lighthouse.IsUnderwater(player)
    Debug.TraceUser(LOG_NAME, "[ENV] underwater = " + underwater)

    ; === LOCATION ===
    Cell currentCell = player.GetParentCell()
    if currentCell
        String cellName = Lighthouse.GetCellName(currentCell)
        bool exterior = Lighthouse.IsExterior(currentCell)
        Debug.TraceUser(LOG_NAME, "[LOC] cell = " + cellName + ", exterior = " + exterior)
    endif

    ; === SHOW SUMMARY IN-GAME ===
    Debug.Notification("[Probe] mag:" + magCur + "/" + magCap + " det:" + detected + " hostiles:" + hostileCount)
EndFunction
