# Rift Stage 6 — Shop, economy & save spec (merged by design workflow)

## scores

Checked against the live place (studio "rift", placeId 123656256423285) before scoring.
- The Weapons tab is StarterPlayerScripts.RiftArsenal.
- RiftCombat.reset() (lines 13-16) applies RiftPending<slot> without re-checking IsUnlocked. Design 3's claim is confirmed.
- RiftElimination fires from RiftCombat line 109 for any player-on-player kill.
- RiftDuel.finish(match,message,winner) is a local function. PlayerRemoving calls finish(...,"Match ended by forfeit",3-team) as soon as a team is empty, so an instant forfeit win is possible.
- match = {size, players, teams, stats[p]={kills,deaths}, score, round, phase="Voting"|"Preparing"|"Countdown"|"Fight"|"Intermission"|"Finished"}.
- RiftWeaponModels.create(w, skin) ALREADY accepts skin = {id, paint, trim, dark, steel, material}.
- RiftUIController shows only the single highest-priority wanted screen. Menu=20, Arsenal=22, Loadout=22, Vote=30, Scoreboard=10.
- Nav badges are client-set attributes (RiftSettings line 224).

D1 DATA SAFETY: safety 9, economy 5, security 8, buildability 5.
- Safety 9: the best save core. Record = {seq, lock, data}; the UpdateAsync transform aborts on a sessionId or seq mismatch; a failed load becomes read-only and is never overwritten with defaults; validation runs before every write; there is a separate _Studio store and a MockStore. Minus 1: it locks on game.JobId semantics in places (JobId is "" in Studio), and the MessagingService release adds complexity.
- Economy 5: three currencies plus a Core-to-Key conversion plus RNG caches is too much. Loot caches are a gambling-adjacent surface the owner never asked for. Only 8-12 free weapons, with a weak first-session hook.
- Security 8: strong ordered validation, a nonce cache, a busy flag and server prices. It misses the reset() pending bypass, and its nonces are not persisted.
- Buildability 5: MessagingService, an admin restore command, caches, key conversion and three currencies are too much for one pass.

D2 ECONOMY & FEEL: safety 7, economy 9, security 6, buildability 7.
- Safety 7: correctly uses a per-server GUID instead of JobId, never writes defaults on failure, and has a lock-steal check. It has no seq check and a flat record (the lock lives inside the data copy).
- Economy 9: 12 free starters, a 500 welcome grant, a first unlock in session 1, about 1,400 Shards/h, a "Next unlock" goal card and the loss bonus all feel good. There are no loot boxes, and every price is a known item. Minus 1: the badge/seenAffordable bookkeeping is over-engineered.
- Security 6: relies on attributes only, misses the reset() pending bypass and the instant-forfeit farm, and pays kills instantly (so leavers keep kill pay).
- Buildability 7: clear, but its per-line, per-weapon skin lists and many bundles inflate the content work.

D3 EXPLOIT RESISTANCE: safety 8, economy 5, security 10, buildability 6.
- Safety 8: same-key atomicity, never saves an offline profile, and handles readonly for newer versions. It uses game.JobId as the lock owner (breaks in Studio), and the offline escrow plus background merge is complex.
- Economy 5: 31 of 40 weapons locked, 49k to unlock everything and about 30 h are too grindy for a game where every weapon is currently free. The movement-sampling activity rule is heavy.
- Security 10: verified live-place facts (FFA kill sources, forfeit farming, reset() pending gap). Adds an ownership provider, every equip path closed, persisted txn idempotency, strict arg validation, escrowed payouts, zero payout in private servers, and pair decay.
- Buildability 6: the RiftDamage event, per-second position sampling, escrow merge and lobby-stand prompts add many touch points.

MERGED: D1's save core (wrapped record, seq plus a session GUID per D2, read-only on failure, validation before every write, MockStore), D2's economy (2 currencies, 12 starters, welcome grant, no RNG), and D3's security (ownership provider, reset() fix, escrowed match payout, forfeit and private-server rules, persisted txn ids, arg validation). D1's MessagingService, caches and admin restore are cut, as are D3's movement sampling and offline escrow merge.

## profileSchema

DataStore name: "RiftProfile_v1", or "RiftProfile_v1_Studio" when RunService:IsStudio(). Key: "u_"..UserId. All writes use UpdateAsync(key, fn) with keyInfo userIds {UserId}.

RECORD (the stored value; the lock lives outside the data so a data copy never carries a lock):
{
  schema = 1,
  seq = 0,                                   -- +1 on every successful write by this design
  lock = nil | { session = string, job = string, t = number },  -- session = HttpService:GenerateGUID(false), made once per server at RiftData load; job = game.JobId (informational only); t = os.time()
  data = PROFILE,
}

PROFILE (template RiftData.TEMPLATE, deep-copied for new players):
{
  v = 1,                                     -- CURRENT_VERSION = 1
  shards = 500,                              -- welcome grant is the default value. Integer 0..1e9
  cores = 0,                                 -- integer 0..1e9
  owned = {
    weapons = {},                            -- {["9"]=true}. PURCHASED weapons only; starters come from Catalog.STARTERS and are never stored, so changing the starter list never needs a migration
    skins = {},                              -- {["9:ember"]=true}, key = "<weaponId>:<styleId>"
  },
  equipped = {
    loadout = {1, 2, 21, 23},                -- contiguous array[4] of weapon ids, one per slot
    skins = {},                              -- {["9"]="ember"}
  },
  daily = { day=0, earned=0, coresEarned=0, lastClaim=0, streak=0, firstWinDay=0 },  -- day = os.time()//86400 (UTC); earned/coresEarned reset when day changes
  firsts = { match=false, win=false },
  pairs = {},                                -- {["<oppUserId>"]={d=day,n=count}}; drop entries where d ~= today on load and on write; max 64 entries
  txn = {},                                  -- array, last 32 {id=string, code=string}; makes purchases idempotent across retries and rejoins
  ledger = {},                               -- array, last 50 {t, k="buy"|"earn"|"daily"|"grant", o=offerId|reason, s=dShards, c=dCores}
  stats = { kills=0, deaths=0, matches=0, wins=0, roundsWon=0, shardsEarned=0, shardsSpent=0, coresEarned=0, coresSpent=0, purchases=0 },
  flags = { review=false, founder=false },
  orphaned = {},                             -- owned ids no longer in the catalog are moved here, never deleted
  created = os.time(), saved = 0, saves = 0,
}

RULES
- JSON safety: dictionaries use string keys only; arrays are contiguous; there are no Instances, Color3 values or NaN.
- MIGRATE: for n = data.v .. CURRENT-1, run data = MIGRATIONS[n](deepCopy(data)) inside pcall. If a migration errors, or data.v > CURRENT (a rolling update loaded a newer save on an older server), the state becomes "readonly". Never write or downgrade in that case. Keep every migration forever.
- RECONCILE: fill any missing key from TEMPLATE without touching existing values.
- SANITIZE on load:
  - shards and cores must be finite integers in [0,1e9]; otherwise clamp and set flags.review=true.
  - Unknown weapon ids and skin keys move to orphaned.
  - Each equipped.loadout[slot] must be in weapons.Loadouts[Slots[slot].category] and owned (a starter or in owned.weapons); otherwise use Slots[slot].default.
  - equipped.skins entries must be owned; otherwise clear them.
- validate(data) runs before EVERY write:
  - currencies are integers in [0,1e9];
  - #HttpService:JSONEncode(record) < 200,000 bytes;
  - the txn and ledger arrays are trimmed.
  If validation fails, refuse the write, warn, keep the profile dirty, and set flags.review.
- FOUNDER GRANT: if created < Catalog.FOUNDER_END (launch + 14 days, a constant) and not flags.founder, add +1,500 Shards, set flags.founder=true and write a ledger entry with k="grant". This softens locking weapons that are free today.

MIRRORED TO CLIENTS (server writes only; never read back as truth):
- RiftShards, RiftCores
- RiftProfileState = "loading" | "ready" | "nosave" | "offline" | "readonly"
- RiftLocked<id> = true for every weapon that is not owned and not a starter (keeps the existing RiftArsenal lock UI working)
- RiftSkins = JSON of equipped.skins (other clients render skins from this)
- RiftLifetimeWins = stats.wins
- RiftMatchEarn = the live escrow shown during a match

## saveStrategy

MODULE: ServerScriptService.RiftData (ModuleScript)
API: Get(player) -> profile|nil, State(player), MarkDirty(player), SaveSoon(player), Grant(...) (used by RiftEconomy), OnReady(player, fn).
It is required at the top of RiftCombat, RiftEconomy, RiftShopServer and RiftLobbyDisplays, so the ownership provider is installed before any remote can fire.

SERVER SESSION ID: SESSION = HttpService:GenerateGUID(false), made once per server. Do not use game.JobId, which is "" in Studio and collides between test sessions.

LOAD (PlayerAdded; also loop over existing players)
1. Fail closed: set RiftProfileState="loading" and RiftLocked<id>=true on every non-starter weapon. The ownership provider allows only starters until the profile is "ready".
2. Call store:UpdateAsync(key, fn). fn(old) must be pure apart from setting locals, because UpdateAsync may call it more than once:
   - old == nil: return {schema=1, seq=0, lock={session=SESSION, job=game.JobId, t=now}, data=deepCopy(TEMPLATE)}.
   - old.lock exists, old.lock.session ~= SESSION and now - old.lock.t < 300: set busy=true and return nil (cancel the write).
   - Otherwise (the lock is free, ours, or stale): set old.lock={session=SESSION, job=game.JobId, t=now} and return old.
   Then lastSeq = result.seq.
3. Error handling: wrap each attempt in pcall. Retry up to 5 times with waits of 1, 2, 4, 8, 8 s (+ math.random()*0.5). Before every call, wait while DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync) < 1 (poll every 1 s, at most 10 s).
4. LOCK BUSY: wait 5 s and retry, up to 6 times (about 30 s, which covers teleports and fast rejoins while the old server's release save lands). Still busy: player:Kick("Your Rift progress is still saving on another server. Rejoin in a minute."). Never load defaults.
5. ALL ATTEMPTS ERRORED:
   - The state becomes "offline". The player keeps playing with starters only.
   - The shop and earning are disabled; the banner reads "Progress offline - rejoin to save".
   - The profile is NEVER saved, because that would overwrite real data with defaults.
   - A background retry of the full LOAD runs every 60 s while the player is present. On success it switches to "ready". Nothing is earned while offline, so no escrow merge is needed.
6. SUCCESS: migrate, reconcile, sanitize, apply the founder grant, then set the state to "ready" (or "readonly").
   - Apply the loadout attributes RiftPrimary/RiftSecondary/RiftMelee/RiftUtility from equipped.loadout.
   - Clear RiftLocked for owned weapons; set RiftSkins, RiftShards and RiftCores.
   - Fire ResetCombat so the loadout takes effect.
   - If the player left during the load, run Save(release=true) immediately.

SAVE (Save(player, release))
- Allowed states: "ready", plus "nosave" in Studio (writes go to the MockStore). Never in "offline" or "readonly".
- One save in flight per player (saving flag). A request made during a save sets again=true; a release request is sticky.
- Keep at least 7 s between writes to the same key (DataStore limit is 6 s). BindToClose may cut this to the remaining cooldown.
- validate(data) first.
- fn(old):
  - if not old, or not old.lock, or old.lock.session ~= SESSION: set lost="LOCK" and return nil;
  - if old.seq ~= lastSeq: set lost="SEQ" and return nil;
  - otherwise: old.data = deepCopy(profile); old.data.saved = now; old.data.saves += 1; old.seq += 1; old.lock = release and nil or {session=SESSION, job=game.JobId, t=now}; return old.
- Success: lastSeq = newSeq, dirty=false.
- lost: state becomes "readonly". Kick("Your session moved to another server.") so two servers never diverge.
- Errors: 3 retries (1, 2, 4 s) with the budget check, then stay dirty for the next cycle. Never drop data.

TRIGGERS
- Autosave every 60 s per player, staggered (first run at UserId % 60). It writes even when not dirty, because the write refreshes lock.t. The stale threshold of 300 s equals 5 missed cycles. If the budget is below 3, skip saves that are not dirty.
- SaveSoon: 6 s debounce after any purchase, equip change or daily claim.
- Immediate save after a match payout.

PLAYERREMOVING: Save(player, true). Drop the profile from memory only after the save succeeds or its retries are exhausted. If the player is still loading, set releaseOnLoad.

BINDTOCLOSE
- Set closing=true: purchases return "CLOSING" and new loads stop.
- task.spawn Save(p, true) for every loaded profile.
- Wait until all are done or 25 s pass (Roblox allows 30 s). In Studio, wait at most 5 s.

STUDIO
- Use the _Studio store name.
- If the first request fails with an error containing "StudioAccessToApisNotAllowed", "403" or "API Services", switch to an in-memory MockStore with the same UpdateAsync(key, fn) semantics. The state becomes "nosave"; the shop and earning work so the UI can be tested.
- Warn: "Enable Studio Access to API Services (Game Settings > Security) to test real saves."
- Live servers NEVER fall back to the MockStore.

GUARANTEES
- Currency and items share one key and one write. A crash rolls both back together: the worst case is losing up to 60 s of progress (6 s after a purchase), with no duplicates and no item that was paid for but missing.
- The session lock plus the seq check stops two servers writing interleaved copies.
- DataStore versioning (on by default) is the manual recovery path. Admin restore is out of scope for this stage.

## currencies

Two earned currencies, both Rift-original. None are bought with Robux, traded, gifted or converted in Stage 6.

SHARDS (glyph: cyan diamond crystal; attribute RiftShards)
- The main currency.
- Earned from: duel kills, round wins, match completion, match wins, the daily streak, first-time bonuses, the welcome grant and the founder grant.
- Buys: every weapon unlock (so power is never behind the rare currency), Standard, Refined and Elite skin styles, bundles, and daily offers.

CORES (glyph: violet hex core; attribute RiftCores)
- The rare currency, for winning and consistency.
- Earned from: match wins, the first win of the day, streak days 5 and 7, and the first ever win.
- Buys: only the Core Vault skin styles (Keys tab). It is purely cosmetic, a long-term goal for dedicated players.

There is no conversion in either direction, so no loops. Cipher Keys and RNG caches from Design 1 are cut. The "Keys" tab keeps the owner's label and holds Weapon Keys (weapon unlocks) plus the Core Vault.

The "+" buttons on the currency pills open a "How to earn" card, not a store.

## earning

MODULES
- Constants: ReplicatedStorage.RiftEconomyConfig.
- Logic: ServerScriptService.RiftEconomy.
- Every grant goes through RiftData.Grant(player, shards, cores, reason). It requires the state "ready" or "nosave", applies the caps, updates stats and the ledger, sets attributes, marks the profile dirty, and pushes RiftShopSync "delta".
- The client never reports kills, wins or activity.

PLUMBING (small RiftDuel and RiftCombat patches)
- RiftDuel: when the arena is chosen in startVote, set match.startedAt=os.clock(). Count fight time per round as match.fightSeconds += the time spent in "Fight".
- RiftDuel: in endRound, record match.roundWinners[round]=winner.
- RiftDuel: in the existing eliminated.Event handler, only when match.phase=="Fight", also append the victim's UserId to match.stats[attacker].victims.
- RiftDuel.finish fires a new BindableEvent ServerScriptService.RiftMatchResult(summary) BEFORE the 4 s cleanup. summary = {id, size, players (still present), teams, winner, message, forfeit=(message contains "forfeit"), timedOut=(message contains "respawn timed out"), rounds=match.round, fightSeconds, roundWinners, stats (kills, deaths, victims, damage per player)}. Keep the existing RiftMatchWins increment.
- RiftCombat damage(): when both attacker and victim are players, fire a new BindableEvent ServerScriptService.RiftDamage(attacker, victim, dealt). RiftDuel adds dealt to match.stats[attacker].damage if they share a match. This is the activity signal.
- RiftEconomy also listens to RiftElimination only to bump the live escrow display (RiftMatchEarn) for duel kills; nothing is credited until the match ends.

AMOUNTS (Shards unless noted)
- Kill: 10. Pays only during Fight, in the same match, on opposite teams, with the victim's AccountAge >= 3. At most 25 paid kills per match.
- Round won: 15 to each winning-team player still present.
- Match completed (present at finish): 40.
- Loss bonus: 5 per round your team won.
- Match won: 100 + 1 Core. Cores from wins are capped at 5 per UTC day.
- First win of the UTC day: +150 + 2 Cores (daily.firstWinDay).
- First completed match ever: +250. First win ever: +300 + 3 Cores.
- Daily streak claim (Daily tab, once per UTC day; the streak resets if today - lastClaim >= 2): days 1-7 pay 50, 75, 100, 125, 150 (+1 Core), 200, 300 (+3 Cores), then the cycle repeats.
- Typical 1v1 first-to-5: a win pays about 265 + 1 Core and a loss about 70. That averages about 170 per match, about 1,350/h at 8 matches an hour.
- First session: 500 welcome + 250 first match + one match puts the player at about 820-1,015 Shards, so the first Tier A unlock (750) comes after match 1.
- Full arsenal: 32,750, about 24 h.

COUNTED MATCH: rounds >= 3 AND fightSeconds >= 90 AND not timedOut.
- Uncounted matches still pay kills and rounds (these are already gated by live opponents), but no completion, win, firsts or Cores.
- Forfeit wins (opponents left) pay in full only if the match already counted (D3). This closes the instant-forfeit alt farm.
- LEAVERS forfeit everything. Payout happens only at finish to players still present (escrow, D3).
- ACTIVITY: a player with 0 damage dealt AND 0 kills in the match gets no completion, win or loss bonus (D2's AFK rule, using RiftDamage).

MULTIPLIERS, applied in order to match Shards and Cores (the daily claim is exempt)
a) Private or VIP server (game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0): x0. The payout panel shows "Private server: no rewards".
b) Repeat opponents: profile.pairs[oppId].n counts today's counted matches against that opponent; take the max over all opponents. n 1-4: x1.0; 5-7: x0.5; 8+: x0.1. This is persisted, so it works across servers.
c) Daily soft cap on match Shards: full rate until daily.earned reaches 4,000, x0.25 until 8,000, then 0.
d) Sanity clamp of 600 Shards per match. Above 400 (1v1) or 550 (3v3), log and set flags.review.

Training Arena, explore-map FFA (RiftElimination with no shared duel match), training dummies and self-kills pay 0. Because payment is gated on the RiftDuel match context, it does not matter where RiftElimination fires.

After the payout, fire RiftShopSync "payout" {lines={{"Kills x5",50},{"Rounds x5",75},...}, notes={"Repeat opponent x0.5"}, shards, cores} for the end-of-match summary. Then call RiftData save-now.

## catalog

MODULES
- ReplicatedStorage.RiftShopCatalog: pure data plus pure functions, shared. The client uses it for display only; the server resolves every price from its own copy.
- ReplicatedStorage.RiftSkins: the style definitions.
- CATALOG_VERSION (int): bump it whenever prices change.

STARTERS (free, never stored), 12 of 40, one per family where possible. The owner should hand-check the list.
- Primary: 1 Vanguard Rifle, 5 Rush SMG, 6 Breach Shotgun, 7 Horizon Sniper
- Secondary: 2 Scout Pistol, 4 Viper Pistol
- Melee: 21 Fists, 24 Knife, 25 Katana
- Utility: 23 Grenade, 33 Smoke Grenade, 35 Medkit
Ids are authoritative; names are as the live RiftWeapons lists them.

WEAPON KEYS (offerId "w:<id>", Shards). There are 28 locked weapons, priced by novelty, not power (all are sidegrades).
- Primary (15,750):
  - Tier A 750: 3 Longshot Carbine, 9 Spectre SMG, 12 Needle PDW
  - Tier B 1,500: 10 Talon Rifle, 13 Hammer Shotgun, 14 Vector DMR, 20 Drift Auto Shotgun
  - Tier C 2,500: 11 Anchor LMG, 15 Sentinel Sniper, 19 Nova Launcher
- Secondary (4,500): 750: 16 Warden Revolver, 17 Ember Auto Pistol. 1,500: 18 Kestrel Heavy Pistol, 8 Arc Launcher.
- Melee (5,000): 500: 26 Scythe, 27 Battle Axe, 29 Trowel, 30 Spear. 1,000: 22 Chainsaw, 28 Riot Shield, 31 Maul.
- Utility (7,500): 750: 32 Flashbang, 34 Molotov, 36 Satchel, 40 Elixir. 1,500: 37, 38, 39.
- Total: 32,750 Shards.
- Catalog.weaponPrice(id) returns nil for starters, else {cur="shards", amt}.

SKIN STYLES (offerId "s:<weaponId>:<style>"). A style applies to any weapon except 21 Fists in v1, because gloves use a separate recolour path. Each style is a table passed straight to the existing RiftWeaponModels.create(w, skin): {id, paint, trim, dark?, steel?, material?, trimMaterial?}. trimMaterial is a one-line addition next to the existing material loop at line 268.
- Standard, 300 Shards:
  - "graphite": matte graphite, gunmetal trim, SmoothPlastic
  - "sandline": desert tan, dark trim
- Refined, 700 Shards:
  - "ember": charcoal paint, burnt-orange trim
  - "glacier": ice blue, white trim, Glass trim
  - "verdigris": oxidised green, Metal
- Elite, 1,500 Shards:
  - "nightfall": deep navy, gold trim
  - "halcyon": pearl white, gold trim, SmoothPlastic
- Core Vault, Cores only:
  - "voidglass" (25 Cores): black Glass body, violet Neon trim
  - "riftborn" (40 Cores): black Slate body, cyan Neon seams
- 9 styles x 39 weapons = 351 SKUs, with no per-weapon authoring. Owning a skin does not require owning the weapon.

BUNDLES (offerId "b:<name>", Shards)
- Price = round to nearest 50 of (discount x the sum of list prices of UNOWNED contents), recomputed by the server at purchase time. If everything is owned the card shows OWNED and the offer can't be bought. Buying grants only the missing items.
- "b:recruit", discount 0.7, shown only while now < created + 7 days: 9 Spectre SMG + "1:ember". List 1,450, price 1,000.
- "b:frontline", 0.8: 10 Talon Rifle + 18 Kestrel Heavy Pistol + "10:ember". List 3,700, price 2,950.
- "b:closequarters", 0.8: 13 Hammer Shotgun + 26 Scythe + 34 Molotov. List 2,750, price 2,200.
- "b:longwatch", 0.8: 15 Sentinel Sniper + 16 Warden Revolver + 36 Satchel. List 4,000, price 3,200.
- "b:nightfall", 0.8: "nightfall" on 1, 2 and 24. List 4,500, price 3,600.

DAILY ROTATION (offerId "d:<day>:<slot>", day = os.time()//86400 UTC)
- rng = Random.new(day*7919 + 1013), drawn over sorted catalog lists. The rotation is not personalised, so every server and client agrees.
- Slots 1-2: Standard skins at -25%. Slots 3-4: Refined skins at -25%. Slot 5: a locked weapon at -25%. Slot 6 (Spotlight): an Elite skin at -20%.
- Rounding: to the nearest 50 for weapons, the nearest 10 for skins.
- The server accepts day == today, or day == today-1 within 120 s after rollover. Anything else returns OFFER_EXPIRED.
- Items already owned show OWNED. There is no 7-day no-repeat rule (cut for simplicity).

FEATURED (Home): the Spotlight (slot 6) item, alternating by day parity with the bundle at index (day//7) % #bundles.

FUTURE (wraps, charms, finishers): new owned.<kind> dictionaries added via Reconcile, with the same offerId scheme ("x:<kind>:..."). No migration is needed.

## remotesAndSecurity

NEW REMOTES (ReplicatedStorage)
- RiftShop (RemoteFunction, client to server only; the server never calls InvokeClient). Usage: InvokeServer(action:string, payload:table?) returns {ok:boolean, code:string, ...}.
  - "snapshot": returns {shards, cores, ownedWeapons, ownedSkins, equippedSkins, daily={day, offers, streak, canClaim, resetAt}, firsts, catalogVersion, state}.
  - "purchase": {offer:string, txn:string, price:number, cur:"shards"|"cores"}.
  - "equipSkin": {weapon:number, style:string|false}. false = default finish.
  - "claimDaily": no payload.
- RiftShopSync (RemoteEvent, server to client only; OnServerEvent is never connected). Messages:
  - "delta" {shards, cores, granted}
  - "payout" {lines, notes, shards, cores}
  - "state" {state, msg}
  - "offer" offerId (opens ShopConfirm, e.g. from a lobby stand)

ARG VALIDATION (one validate per action; failure returns BAD_ARGS and counts a strike)
- action must be one of the 4 strings.
- payload is nil, or a table with 4 or fewer string keys and no nested tables.
- Strings: typeof=="string", 48 characters or fewer, matching ^[%w_:%-]+$.
- txn: 8-48 characters.
- Numbers: typeof=="number", n==n (not NaN), math.abs(n) < 1e7, n%1==0.
- weapon must be in 1..40 and style must be in RiftSkins.
- Client values are never used as table keys before validation.

RATE LIMITS (per player, os.clock())
- Token bucket of 6 tokens refilling at 3/s; empty returns RATE.
- snapshot and claimDaily: 1 per 2 s (snapshot returns a cached copy instead).
- 60 or more strikes in a minute: warn and drop that player's shop calls for 30 s. No auto-kick.
- The existing RiftAction "loadout" gains a 0.15 s per-player throttle.

PURCHASE TRANSACTION (RiftShopServer). Steps 3-8 contain no yields, so they are atomic under Luau's cooperative scheduling.
1. Rate check. Per-player busy flag: if already set, return BUSY.
2. State must be "ready" (or "nosave" in Studio) and not closing. Otherwise return NOT_LOADED, OFFLINE, READ_ONLY or CLOSING.
3. If txn is in profile.txn, return {ok=true, dup=true, code=stored code} plus current balances and charge nothing. This makes double clicks, timeouts and rejoin retries safe.
4. offer = Catalog.Resolve(offerId, os.time(), profile) using server prices, the daily rotation and bundle proration. Unknown returns UNKNOWN_OFFER; rotated out returns OFFER_EXPIRED; an expired recruit bundle returns OFFER_EXPIRED.
5. If every grant is already owned, return ALREADY_OWNED.
6. If payload.price ~= offer.price or payload.cur ~= offer.cur, return PRICE_CHANGED with the new price. Nothing is charged; the client re-confirms.
7. If the balance is below the price, return INSUFFICIENT with the shortfall.
8. MUTATE:
   - deduct the balance;
   - set owned for each missing grant;
   - update stats (spent, purchases);
   - push {id=txn, code="OK"} to profile.txn (trim to 32);
   - push a ledger entry.
9. Clear busy. Mirror attributes (RiftShards/RiftCores, RiftLocked<id>=nil). MarkDirty plus SaveSoon. FireClient "delta". Return {ok=true, code="OK", shards, cores, granted}.

OWNERSHIP PROVIDER (closes every equip path; D3)
- RiftWeapons.IsUnlocked becomes: if weapons.OwnershipProvider then return weapons.OwnershipProvider(player,id) end; otherwise fall back to the existing attribute rule (which the client uses).
- RiftData installs the provider on the server: a starter returns true; a state other than "ready"/"nosave"/"readonly" returns false; otherwise return owned.weapons[tostring(id)]==true.
- RiftCombat RiftAction "loadout" (line ~217) is already covered through IsUnlocked. Add the throttle, and on acceptance write profile.equipped.loadout[slot] (the target id, pending or applied) plus SaveSoon.
- RiftCombat.reset() lines 13-16 (CONFIRMED bypass): change to `if pending then if weapons.IsUnlocked(p,pending) then apply end; clear pending end`. After that loop, any slot whose weapons.GetId is not unlocked is set to Slots[slot].default. This also covers rollbacks.
- RiftLobbyDisplays Equip prompt (line 10) is already covered. When the weapon is locked, fire RiftShopSync(player,"offer","w:"..id) instead of silently returning.
- equipSkin: the server checks owned.skins[weapon..":"..style] (or style==false), writes equipped.skins and the RiftSkins attribute, then SaveSoon.
- Other players' rendering of skins reads only the server-set RiftSkins attribute. A hacked client can only fake cosmetics locally, which is accepted.
- Earning is server-only (RiftMatchResult, RiftDamage, RiftElimination BindableEvents); no client remote feeds the economy.
- No admin grant remote. Test grants go through a server-only command list keyed by UserId, Studio only.

ATTRIBUTE TRUST: attributes the client sets do not replicate, so RiftLocked*, RiftShards and similar values are tamper-proof server-side. The server still never reads them back; the profile table is the truth.

## uiNotes

UI CONTROLLER FACTS: RiftUIController shows exactly one screen, the highest-priority wanted one. Existing priorities: Menu 20, Arsenal 22, Loadout 22, Vote 30, Scoreboard 10.
- Register("Shop", screen, 22) as a peer of Arsenal. Opening Shop calls Set("Arsenal",false) and vice versa, so the two never tie.
- Register("ShopConfirm", confirm, 26): above Shop, Arsenal and Loadout, below Vote. It is a full-screen purchase confirmation (it hides the screen beneath). Closing it automatically returns to whichever of Shop/Arsenal/Loadout is still wanted.
- Arsenal's changed(false) callback must not reset the selection or camera when it is only covered by ShopConfirm (check RiftArsenal line 363).

NEW LocalScript StarterPlayerScripts.RiftShopUI, built with RiftUI helpers (button, text, badge, frame)
- Shared module ReplicatedStorage.RiftPurchasePrompt, a client-only ModuleScript used by the Shop, Arsenal, the Loadout picker and the lobby "offer" event. It owns the ShopConfirm view and the purchase call. It is a ModuleScript in ReplicatedStorage because it must be required by several LocalScripts.
- Lobby nav "Shop" button:
  - enabled when RiftProfileState is "ready" or "nosave";
  - "Loading..." while loading;
  - in "offline"/"readonly" it opens view-only with a banner.

TOP CURRENCY BAR (Shop and Arsenal)
- A Shards pill (cyan crystal glyph) and a Cores pill (violet hex), bound to GetAttributeChangedSignal for RiftShards/RiftCores.
- Gains count up over 0.4 s with a "+N" float.
- "+" opens the "How to earn" card.
- A status chip shows "Saved" / "Offline" / "Studio: saves off" from RiftProfileState.

TAB ROW: Home | Bundles | Skins | Daily | Keys (dot badge per tab)
- HOME: a large FEATURED PANEL on the left (about 60%): a ViewportFrame slowly rotating RiftWeaponModels.create(w, style), with name, tier strip, price badge, BUY and PREVIEW IN ARSENAL. On the right:
  - a "NEXT UNLOCK" goal card: the cheapest locked weapon, a progress bar such as "620 / 750", and "~1 match" using 170 per match;
  - the first 3 daily offers;
  - a "Claim daily reward" tile that pulses when claimable.
- BUNDLES: wide cards with content icons and owned ticks, the struck-through list sum, the prorated price, "-20%" (or "-30%"), and an "Ends in Xd" ribbon on Recruit.
- SKINS: slot chips (All/Primary/Secondary/Melee/Utility), a weapon dropdown (defaults to the currently equipped primary) and tier chips, over a grid of item cards. The grid is paged or virtualised: build at most 24 cards at once, with viewports only for visible cards.
- DAILY: 6 offer cards with discount ribbons; "Resets in 07:42:10" counting to the next UTC midnight from workspace:GetServerTimeNow(); the 7-day streak track with a CLAIM button.
- KEYS: a "Weapon Keys" section with locked weapons grouped by slot (class, family, description, price), and a "Core Vault" section with voidglass/riftborn previews and the line "Cores come from duel wins and streaks".

ITEM CARD
- A tier colour strip: Standard grey, Refined teal, Elite gold, Vault violet, Weapon cyan.
- Viewport or icon, name, and the weapon name.
- PRICE BADGE bottom-right (glyph + amount): full colour if affordable; dimmed with "Need X more" if not.
- Discount ribbon plus struck-through price where applicable.
- OWNED / EQUIPPED pill.

PURCHASE CONFIRMATION (ShopConfirm)
- Large preview, name and tier, the grant list ("Unlocks permanently" / "Skin for <weapon>" / bundle contents), the price, and "Balance 1,240 -> 490".
- CONFIRM / CANCEL. CONFIRM disables itself immediately and shows a spinner.
- txn = HttpService:GenerateGUID(false), generated ONCE per opening of the confirm screen and reused on retry.
- Code-to-text mapping:
  - INSUFFICIENT: "Not enough Shards - about N matches"
  - PRICE_CHANGED: show the new price and confirm again
  - OFFER_EXPIRED: "This offer rotated out"
  - BUSY/RATE: "Try again"
  - NOT_LOADED/OFFLINE: a banner
- On success: a flash, plus EQUIP NOW for weapons and skins. EQUIP NOW uses the existing RiftAction "loadout" for weapons and equipSkin for skins.

WEAPONS TAB INTEGRATION (the user's request; patch StarterPlayerScripts.RiftArsenal)
- Sidebar rows (around line 211): a locked weapon's lock tag becomes a price pill "<crystal> 1,500". It is accent-coloured if affordable, danger-coloured if not, and gets a "-25%" ribbon if the weapon is in today's daily slot 5.
- Equip card for a locked weapon (around line 232):
  - the status line reads "Locked - 1,500 Shards";
  - the action button becomes "UNLOCK - 1,500", which opens ShopConfirm with "w:<id>" (or with the daily offer id when that offer is cheaper);
  - if the player can't afford it: "NEED 420 MORE", disabled, with the hint "Win duels to earn Shards".
  - After the purchase the RiftLocked attribute clears and the row unlocks in place; it can be equipped immediately and applies at the next respawn.
- The bottom "Skin" round button (line 143) loses its SOON pill and opens a skin strip above the action row: Default plus the 9 styles for the selected weapon, each with an OWNED/EQUIPPED/price badge.
  - Clicking a style PREVIEWS it on the 3D stage model (client-only, with a "PREVIEW" pill).
  - EQUIP (owned) calls equipSkin. BUY opens ShopConfirm with "s:<id>:<style>".
  - Wrap, Charm and Finisher stay SOON.
- The stage model and row icons use the equipped style from the RiftSkins attribute.
- The M loadout picker (line 349) currently filters locked weapons out. Show them dimmed, with a price badge; tapping one opens ShopConfirm.
- Shop "Preview in Arsenal" opens Arsenal on that weapon and style through a BindableEvent RiftArsenalSelect(id, style) under PlayerScripts.
- Everything refreshes on attribute changes to RiftLocked<id>, RiftShards, RiftCores and RiftSkins.
- Lobby display stands: a locked Equip prompt opens ShopConfirm through RiftShopSync "offer". A second "Unlock" prompt is a stretch goal.

BADGES (client-computed; cosmetic, so client trust is fine)
- RiftBadgeShop = (canClaim ? 1 : 0) + (today's rotation not yet viewed ? 1 : 0). "Viewed" is stored client-side for the session and keyed by day.
- RiftBadgeArsenal (only if the nav has that button) = locked weapons now affordable that weren't affordable when the tab was last opened this session.

END-OF-MATCH PAYOUT PANEL
- Fed by RiftShopSync "payout": itemised lines with a count-up, small notes (repeat opponent x0.5, soft cap, private server), and the "Next unlock" bar moving.
- During a match, a small "+N" tally reads the RiftMatchEarn attribute (shown as pending until the match finishes).

## buildOrder

Create a backup first: ServerStorage.RiftBackup_<date>_preStage6 (same pattern as the existing preStage1 backup).

6a. DATA CORE
- New ModuleScript ServerScriptService.RiftData: TEMPLATE, MIGRATIONS, reconcile/sanitize/validate, MockStore, LOAD/SAVE/autosave/PlayerRemoving/BindToClose, Grant, ownership provider install.
- New ReplicatedStorage.RiftEconomyConfig: all numbers.
- New ReplicatedStorage.RiftShopCatalog: STARTERS, weapon prices, bundles, daily generator, Resolve, FOUNDER_END, CATALOG_VERSION.
- New ReplicatedStorage.RiftSkins: the 9 styles.
- Patch ReplicatedStorage.RiftWeapons.IsUnlocked to the OwnershipProvider form.
- Test in Studio with API access OFF (MockStore, "nosave") and ON (_Studio store): rejoin persistence, plus a forced-failure flag that proves "offline" never writes.

6b. LOADOUT PERSISTENCE AND EQUIP HARDENING (ServerScriptService.RiftCombat)
- Require RiftData.
- Fix reset() pending (lines 13-16) and add the post-loop default fallback.
- Throttle "loadout" and write equipped.loadout plus SaveSoon.
- Patch ServerScriptService.RiftLobbyDisplays for the locked weapon offer. RiftShopSync must exist first; create it in this step.

6c. EARNING
- New BindableEvents ServerScriptService.RiftMatchResult and ServerScriptService.RiftDamage.
- Patch ServerScriptService.RiftDuel:
  - match.startedAt, fightSeconds, roundWinners;
  - victims and damage in match.stats;
  - a Fight-phase check in the eliminated handler;
  - fire RiftMatchResult in finish() before the cleanup delay.
- Patch RiftCombat damage() to fire RiftDamage.
- New Script ServerScriptService.RiftEconomy: escrow display, counted-match rules, multipliers, payout, daily claim logic (shared with the shop), firsts, "payout" event.

6d. SHOP SERVER
- New RemoteFunction ReplicatedStorage.RiftShop.
- New Script ServerScriptService.RiftShopServer: validation, rate limits, snapshot, purchase transaction, equipSkin, claimDaily.
- Small patch to ReplicatedStorage.RiftWeaponModels: optional skin.trimMaterial, applied next to line 268. Then wherever world and view models are created, pass RiftSkins[ownerId][weaponId] (grep call sites of Models.create).

6e. SHOP UI
- New ModuleScript ReplicatedStorage.RiftPurchasePrompt (ShopConfirm, priority 26).
- New LocalScript StarterPlayerScripts.RiftShopUI: currency bar, 5 tabs, cards, featured panel, payout panel.
- Patch StarterPlayerScripts.RiftSettings to enable the "Shop" nav button gated on RiftProfileState, and wire RiftBadgeShop.

6f. WEAPONS TAB INTEGRATION
- Patch StarterPlayerScripts.RiftArsenal: price pills, the UNLOCK button, the skin strip with preview, equip/buy, the M picker showing locked weapons with prices, and the RiftArsenalSelect deep link.

6g. TESTS
- Team Test with 2 players: a full duel payout, a leaver gets nothing, an instant forfeit pays no win bonus, the Training Arena pays 0.
- Spam purchase and equip remotes from the command bar on the client: expect BUSY/RATE and no double charge. Repeat the same txn: dup=true.
- Set a RiftPending on a locked weapon: reset() refuses it.
- Two-server lock handoff (rejoin quickly): a wait, then a load, with no rollback.
- BindToClose save on Studio stop.
- A migration fixture record with v=0 and one with v=2 (expect readonly).
- Economy sanity check: first unlock after one match.

## openRisks

1. LOCKING 28 OF 40 WEAPONS that are free today. Mitigated by 12 starters, a 500 welcome grant, a 1,500 founder grant (14 days) and a first unlock after 1 match. The owner must still approve the starter list and announce the change.
2. NAMING: the live RiftWeapons includes "Subspace Tripmine", "Warper" and "Warpstone" (ids 37-39 range). Design 3 noted that some additions borrow another game's catalogue. Rename them to Rift-original names before they are sold. This is why they are kept out of bundles and the featured slot.
3. Session-lock friction: after a server crash a player can be blocked for up to 5 minutes (the stale window). Fast hops wait up to 30 s, then get a clear kick message. MessagingService release is deliberately cut; add it later if this hurts.
4. DataStore outage: the player plays starters-only, with no earning and no shop. Earnings during an outage are not escrowed (accepted for simplicity). The background reload every 60 s recovers mid-session.
5. Crash rollback: up to 60 s of progress (6 s after a purchase) can be lost, always with currency and items together, never a dupe.
6. Collusion and alt farming in 1v1 is bounded, not zero: pair decay, AccountAge on kills, counted-match rules, the activity check, daily caps and zero in private servers. Monitor flags.review and stats.shardsEarned outliers. All thresholds are in RiftEconomyConfig.
7. Skin rendering: every call site of RiftWeaponModels.create (viewmodel, third-person, lobby stands, Arsenal icons) must pass the skin. Missing one shows the default finish (cosmetic bug only). The skin.material override only re-materials parts whose colour equals paint. Fists are excluded in v1.
8. UI controller exclusivity: ShopConfirm hides the screen beneath. Verify that Arsenal's changed(false) callback doesn't reset state, and that Shop and Arsenal (both 22) are never wanted at the same time.
9. Skins grid performance: 351 SKUs. Page or virtualise, and only build viewports for visible cards.
10. Economy numbers are estimates (about 170 per match, about 24 h for the full arsenal). Run a tuning pass using stats.matches/shardsEarned; target the first unlock in session 1 and about 1,350 Shards/h.
11. The private-server zero payout may frustrate friend groups. It is a config flag (PRIVATE_SERVER_MULT); revisit after launch.
12. Clock skew at UTC midnight is handled by the 120 s grace and PRICE_CHANGED/OFFER_EXPIRED re-confirm.
13. Studio: testers must enable "Enable Studio Access to API Services" (Game Settings > Security) to exercise real saves. Otherwise the MockStore "nosave" mode runs. Studio always writes to the _Studio store, never to live keys.
14. Out of scope this stage: Robux and MarketplaceService, loot caches, Core to Key conversion, admin restore tooling, and a second lobby-stand Unlock prompt (stretch goal).

