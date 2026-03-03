$ErrorActionPreference = 'Stop'

function Get-MojibakeScore([string]$value) {
  if ([string]::IsNullOrEmpty($value)) { return 0 }
  $latin = ([regex]::Matches($value, '[\u00C0-\u00FF]')).Count
  $replacement = ([regex]::Matches($value, [string][char]0xFFFD)).Count
  return ($latin * 2) + ($replacement * 4)
}

function Repair-Text([string]$value) {
  if ([string]::IsNullOrWhiteSpace($value)) { return '' }

  $current = $value
  for ($i = 0; $i -lt 3; $i++) {
    $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($current)
    $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ((Get-MojibakeScore $decoded) -lt (Get-MojibakeScore $current)) {
      $current = $decoded
      continue
    }
    break
  }

  return $current.Trim()
}

$translationsRaw = @'
1:1|Dhritarashtra said: O Sanjaya, after assembling at Kurukshetra, eager for battle, what did my sons and the sons of Pandu do?
1:2|Sanjaya said: Seeing the Pandava army arranged for war, King Duryodhana approached teacher Drona and spoke these words.
1:3|O teacher, behold this mighty army of the sons of Pandu, expertly arranged by your intelligent disciple, the son of Drupada.
1:4|In this army stand many heroic archers, equal in battle to Bhima and Arjuna.
1:5|There are also great warriors such as Dhrishtaketu, Chekitana, the valiant king of Kashi, Purujit, Kuntibhoja, and Shaibya.
1:6|There are Yudhamanyu, Uttamauja, the son of Subhadra, and the sons of Draupadi, all powerful chariot-warriors.
1:7|Now, O best of brahmanas, know also the distinguished leaders of our own army.
1:8|You, Bhishma, Karna, Kripa, Ashvatthama, Vikarna, and the son of Somadatta are all present.
1:9|Many other brave heroes are here as well, ready to lay down their lives for my sake, armed with many weapons and skilled in war.
1:10|Our strength, protected by Bhishma, seems limitless; their strength, protected by Bhima, seems limited.
1:11|Therefore, stationed at your strategic points, all of you must support and protect Bhishma.
1:12|Then Bhishma, the grandsire of the Kurus, roared like a lion and blew his conch loudly, delighting Duryodhana.
1:13|Immediately conches, drums, kettledrums, trumpets, and horns sounded together with a tremendous uproar.
1:14|Then Krishna and Arjuna, seated in their splendid chariot drawn by white horses, blew their divine conches.
1:15|Krishna blew Panchajanya, Arjuna blew Devadatta, and mighty Bhima blew his great conch Paundra.
1:16|King Yudhishthira blew Anantavijaya, while Nakula and Sahadeva blew Sughosha and Manipushpaka.
1:17|The king of Kashi, the great archer, Shikhandi, Dhrishtadyumna, Virata, and undefeated Satyaki also blew their conches.
1:18|Drupada, the sons of Draupadi, and the strong-armed son of Subhadra all blew their conches from every side.
1:19|That thunderous sound shook earth and sky and pierced the hearts of Dhritarashtra's sons.
1:20|At that moment, Arjuna, whose banner bore Hanuman, lifted his bow and prepared to speak to Krishna.
1:21|Arjuna said: O Achyuta, place my chariot between the two armies.
1:22|Let me see those who stand here eager to fight and with whom I must battle in this great war.
1:23|I wish to observe those gathered here to please the evil-minded son of Dhritarashtra.
1:24|Sanjaya said: Addressed by Arjuna, Krishna drove the excellent chariot to the space between both armies.
1:25|Before Bhishma, Drona, and all the kings, Krishna said: O Partha, behold these Kurus assembled for battle.
1:26|There Arjuna saw fathers, grandfathers, teachers, uncles, brothers, sons, grandsons, friends, and kinsmen on both sides.
1:27|Seeing all his relatives arrayed there, Arjuna was overcome with deep compassion and sorrow.
1:28|Arjuna said: O Krishna, seeing my own people eager to fight, my limbs fail and my mouth dries up.
1:29|My body trembles, my hair stands on end, and my skin burns.
1:30|My bow Gandiva slips from my hand, my mind reels, and I can no longer stand steady.
1:31|I see inauspicious omens, O Keshava; I see no good in killing my own people in battle.
1:32|I do not desire victory, kingdom, or pleasures, O Krishna.
1:33|What use is kingdom or enjoyment to us when those for whom we desire them stand here ready to die?
1:34|Teachers, fathers, sons, grandfathers, uncles, in-laws, grandsons, and many relatives stand here in battle.
1:35|Even for sovereignty over the three worlds, I do not wish to kill them, what to speak of ruling this earth.
1:36|By killing Dhritarashtra's sons, sin alone will come upon us, even though they are aggressors.
1:37|Therefore we should not kill our own kinsmen; how can we be happy after slaying our own people?
1:38|Though their minds are overpowered by greed and they see no wrong in destroying families, we should know better.
1:39|O Janardana, since we clearly see the evil in family destruction, why should we not turn away from this sin?
1:40|With the destruction of a family, its eternal traditions perish; when dharma is lost, adharma prevails.
1:41|When adharma prevails, the women of the family are corrupted, and social disorder arises.
1:42|Such disorder leads both the destroyers of the family and the family itself toward downfall, and the ancestors are deprived of offerings.
1:43|Through these faults, eternal family duties and social order are destroyed.
1:44|We have heard that those whose family traditions are ruined dwell in hell for a long time.
1:45|Alas, we are preparing to commit great sin, driven by desire for royal pleasure and power.
1:46|It would be better for me if the sons of Dhritarashtra kill me unresisting and unarmed on the battlefield.
1:47|Sanjaya said: Speaking thus, Arjuna cast aside his bow and arrows and sat down in the chariot, his mind overwhelmed by grief.
2:1|Sanjaya said: To Arjuna, overwhelmed by pity and sorrow, with tearful eyes and dejected heart, Krishna spoke.
2:2|The Blessed Lord said: From where has this weakness arisen in this critical hour? It is unworthy, dishonorable, and does not lead to higher life.
2:3|Do not yield to this unmanliness, O Partha. Cast off this petty weakness of heart and arise, O scorcher of foes.
'@

$deepDiveRaw = @'
1:1|The Gita begins with a question, not an answer. Dhritarashtra's words reveal anxiety, attachment, and moral uncertainty before action even starts.
1:2|Duryodhana's first move is political: he frames the battlefield through strategy and influence. Fear often hides beneath confident speech.
1:3|By calling attention to Dhrishtadyumna, Duryodhana quietly reminds Drona of old loyalties and tensions. The verse shows how people weaponize relationships in conflict.
1:4|This verse establishes the seriousness of the Pandava side. Underestimating the opponent is replaced by sober recognition of real strength.
1:5|The roll call underscores that dharma-war is not a personal duel but a civilizational conflict involving many noble houses.
1:6|The mention of younger warriors signals continuity across generations. Duty here is inherited, not invented at the last moment.
1:7|Duryodhana shifts from praise to command. In crisis, leaders try to reclaim control by naming structure and hierarchy.
1:8|By naming top veterans, Duryodhana seeks psychological stabilization. Speaking names can be a way of summoning confidence.
1:9|The verse reflects war's total demand: skill, commitment, and willingness to sacrifice life itself. Ideology is now embodied in human risk.
1:10|This is strategic rhetoric, not neutral analysis. Duryodhana tries to elevate morale by projecting invincibility.
1:11|Bhishma becomes the symbolic center of Kaurava confidence. Protecting symbols is often as important as protecting territory.
1:12|Bhishma's conch is a signal of command and emotional ignition. Sound marks the transition from preparation to irreversible action.
1:13|The collective roar creates shared momentum. Public noise can drown private doubt.
1:14|Krishna and Arjuna's conches introduce sacred intentionality. Their response is not louder panic but poised presence.
1:15|Each conch has identity, suggesting that dharma honors individuality within disciplined action.
1:16|The participation of Yudhishthira, Nakula, and Sahadeva shows alignment across temperament and role. Unity is now audible.
1:17|This verse broadens the moral coalition. Dharma is not a lone hero narrative but coordinated righteousness.
1:18|Even allies from different families and generations sound one purpose. Shared conviction turns diversity into strength.
1:19|Psychological warfare begins before physical warfare. Sound penetrates where weapons have not yet reached.
1:20|Arjuna's readiness is visible, but inner conflict is approaching. Outer courage and inner clarity are not always synchronized.
1:21|Arjuna's request is deliberate: before fighting, he wants to see clearly. Ethical action begins with direct perception.
1:22|He asks not for advantage but understanding. Wisdom requires knowing exactly what one is stepping into.
1:23|This verse exposes motive analysis: Arjuna wants to understand who is driven by loyalty, fear, or ambition.
1:24|Krishna complies without argument, honoring Arjuna's process. True guidance often begins by creating the right vantage point.
1:25|Krishna's word 'behold' is diagnostic and spiritual. Seeing fully is the first medicine for confusion.
1:26|Arjuna's battlefield transforms into a family map. Abstract duty collapses into personal memory.
1:27|Compassion here is real, but it is mixed with paralysis. The Gita will teach how to purify compassion into wise action.
1:28|The body registers what the intellect cannot yet process. Spiritual crisis often appears first as physical disturbance.
1:29|Somatic symptoms intensify: trembling, burning, shock. The verse captures authentic human vulnerability.
1:30|Loss of grip on Gandiva symbolizes loss of role-confidence. Identity crisis often follows moral conflict.
1:31|Arjuna's moral instinct rejects violence against kin, but he has not yet integrated duty and compassion. This tension drives the dialogue.
1:32|Pleasure and power lose meaning when conscience is unsettled. Desire collapses in the face of ethical pain.
1:33|Arjuna questions the very purpose of achievement. Ends cannot justify means when the means destroy what gives the end value.
1:34|By naming relationships, he personalizes the cost of war. Dharma cannot be discussed without acknowledging relational consequence.
1:35|Arjuna rejects utilitarian victory. Moral boundaries remain even under maximum possible reward.
1:36|He fears inner corruption more than external loss. The verse reframes success as purity of action, not mere outcome.
1:37|This is a direct ethics question: can happiness be built on betrayal of one's own? Arjuna's answer is no.
1:38|Arjuna distinguishes between their blindness and his responsibility. Dharma does not imitate adharma, even when provoked.
1:39|Knowledge creates duty. Seeing clearly and still acting wrongly becomes a deeper fall.
1:40|Family dharma is presented as social infrastructure. When it collapses, disorder is not immediate chaos but gradual decay.
1:41|Arjuna fears generational moral fracture. Social stability depends on protected dignity and responsible conduct.
1:42|The verse links personal sin to ancestral disruption. In Vedic thought, duty is trans-generational, not individualistic.
1:43|Adharma spreads structurally when institutions fail. Arjuna recognizes that private violence has public consequences.
1:44|Tradition here is not blind ritual but civilizational memory. Destroying it produces long-term spiritual homelessness.
1:45|Arjuna's lament shows conscience awakening under pressure. This painful honesty opens the door to transformation.
1:46|He prefers personal loss over ethically compromised action. Refusal to retaliate can be moral strength, not weakness.
1:47|Action halts; despair peaks. This collapse is the necessary threshold before true wisdom enters.
2:1|Krishna speaks only after Arjuna fully reveals his crisis. Genuine teaching addresses the real wound, not the surface argument.
2:2|Krishna's first response is a wake-up call, not consolation. Compassion can be firm when delusion must be broken quickly.
2:3|The Gita's movement begins: from collapse to courageous clarity. Krishna asks Arjuna to rise, not by anger, but by recovered dharma.
'@

$translations = @{}
foreach ($line in ($translationsRaw -split "`r?`n")) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $sep = $line.IndexOf('|')
  if ($sep -lt 0) { continue }
  $k = $line.Substring(0, $sep).Trim()
  $v = $line.Substring($sep + 1).Trim()
  $translations[$k] = $v
}

$deepDives = @{}
foreach ($line in ($deepDiveRaw -split "`r?`n")) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $sep = $line.IndexOf('|')
  if ($sep -lt 0) { continue }
  $k = $line.Substring(0, $sep).Trim()
  $v = $line.Substring($sep + 1).Trim()
  $deepDives[$k] = $v
}

$palette = @(
  '#FFECD2',
  '#D4FC79',
  '#84FAB0',
  '#FFD194',
  '#FF9A9E',
  '#FEE140',
  '#FA709A',
  '#A1C4FD',
  '#FBC2EB',
  '#C2E9FB',
  '#FCCB90',
  '#C2FFD8',
  '#F6D365',
  '#96E6A1',
  '#B5FFFC',
  '#FFD3A5',
  '#FAD0C4',
  '#B8E0D2'
)

$source = Get-Content 'assets/data/verse.json' -Raw | ConvertFrom-Json
$first50 = $source | Select-Object -First 50

$result = @()
foreach ($row in $first50) {
  $chapter = [int]($row.chapter_number)
  $verseNumber = [int]($row.verse_number)
  $key = "${chapter}:${verseNumber}"

  $id = "BG_{0}_{1}" -f $chapter.ToString('00'), $verseNumber.ToString('00')
  $original = Repair-Text ([string]$row.text)
  $translit = Repair-Text ([string]$row.transliteration)
  $wordMeanings = Repair-Text ([string]$row.word_meanings)

  $translation = $translations[$key]
  if ([string]::IsNullOrWhiteSpace($translation)) {
    $translation = if ([string]::IsNullOrWhiteSpace($wordMeanings)) {
      'Translation is currently unavailable for this verse.'
    } else {
      "Literal meaning: $wordMeanings"
    }
  }

  $deepDive = $deepDives[$key]
  if ([string]::IsNullOrWhiteSpace($deepDive)) {
    $deepDive = 'This verse deepens the chapter narrative and prepares the transition to Krishna’s core teaching on dharma and self-mastery.'
  }

  $result += [ordered]@{
    id = $id
    chapter = $chapter
    verse_number = $verseNumber
    original_script = $original
    transliteration = $translit
    word_meanings = $wordMeanings
    translation_english = $translation
    deep_dive_text = $deepDive
    background_hex_color = $palette[($chapter - 1) % $palette.Count]
  }
}

$json = $result | ConvertTo-Json -Depth 6
Set-Content -Path 'assets/data/verses.json' -Value $json -Encoding utf8
Set-Content -Path 'assets/data/verse.json' -Value $json -Encoding utf8

Write-Output "WROTE_CUSTOM_VERSES_COUNT=$($result.Count)"
