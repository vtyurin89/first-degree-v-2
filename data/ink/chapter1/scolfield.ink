EXTERNAL has_flag(flag)
EXTERNAL has_trait(trait)
EXTERNAL has_confirmed_trait(trait)
EXTERNAL has_suspected_trait(trait)
EXTERNAL has_tactic(tactic)
EXTERNAL has_clue(clue)
EXTERNAL get_attorney_risk()
EXTERNAL add_flag(flag)
EXTERNAL modify_attorney_risk(delta)

-> p1_intro

=== p1_intro ===
Наконец-то. Слушайте, я тут уже два часа торчу. Может, хоть кофе предложите? Или у вас тут так заведено — мариновать людей, пока не сломаются? # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P1_INTRO
-> p1_anna_greeting_1

=== p1_anna_greeting_1 ===
Прошу прощения за задержку, мистер Сколфилд.
 # speaker: anna # id: CH1_DLG_ANNA_P1_GREETING_1
-> p1_anna_greeting_2

=== p1_anna_greeting_2 ===
Я детектив Анна Кроуфорд. Понимаю, что вам сейчас непросто, поэтому давайте разберёмся со всем побыстрее. Не хочу держать вас здесь без необходимости.
 # speaker: anna # id: CH1_DLG_ANNA_P1_GREETING_2
-> p1_anna_greeting_3

=== p1_anna_greeting_3 ===
[url=event:scolfield_misogyny_1]Женщина-детектив, надо же...[/url] [url=event:scolfield_selfishness_1]Так я не арестован?[/url]
 # speaker: scolfield # id: CH1_DLG_ANNA_P1_GREETING_3
-> p1_scolfield_arrest_hub_1


// Arrest question hub 1
=== p1_scolfield_arrest_hub_1 ===
* [Нет, вы здесь по собственной воле и можете уйти когда захотите. Но мне следует зачитать вам права... (зачитать права Миранды) # id: CH1_DLG_SCOLFIELD_ANSWER_IMMEDIATE_MIRANDA]
    -> p1_miranda
* [Нет, мистер Сколфилд, конечно же вы не арестованы. Но вам нужно будет ответить на несколько вопросов. # id: CH1_DLG_SCOLFIELD_ANSWER_IMMEDIATE_NOT_ARRESTED]
    -> p1_scoldield_arrest_answer_good
* [Вы свидетель, а не подозреваемый, никто вас не арестует. # id: CH1_DLG_SCOLFIELD_ANSWER_IMMEDIATE_NOT_SUSPECT]
    -> p1_scoldield_arrest_answer_good
* [Пока что нет. # id: CH1_DLG_SCOLFIELD_ANSWER_IMMEDIATE_NOT_YET]
    -> p1_scoldield_arrest_answer_suspicious

=== p1_miranda ===
Это просто формальность. По новым правилам у нас требуют зачитывать это всем подряд, даже тем, кто просто помогает. Вы имеете право хранить молчание. Всё, что вы скажете, может и будет использовано против вас в суде. Вы имеете право на адвоката. Если вы не можете его себе позволить, он будет предоставлен вам бесплатно. Вам понятны ваши права? # speaker: anna # id: CH1_DLG_SCOLFIELD_P1_MIRANDA
    -> p1_miranda_answer_uncomfortable_1
    
=== p1_miranda_answer_uncomfortable_1 ===
Да... наверное. Но как-то вы внезапно говорите про права... Хах, уж извините, стало как-то не по себе. Мне позвонить адвокату? # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P1_MIRANDA_UNCOMFORTABLE_1
    -> p1_miranda_uncomfortable_hub

=== p1_miranda_uncomfortable_hub ===
* [Это ваше право, мистер Сколфилд. Если хотите позвонить, я остановлю запись прямо сейчас. # id: CH1_DLG_SCOLFIELD_CHOICE_P1_MIRANDA_HONEST]
    -> p1_miranda_clarify_1
* [Вы считаете, что вам нужен адвокат? Я могу остановить допрос, чтобы вы могли позвонить, это ваше право. # id: CH1_DLG_SCOLFIELD_CHOICE_P1_MIRANDA_CLARIFY]
    -> p1_miranda_clarify_1
* [Адвокат вам не понадобится, мистер Сколфилд. Вы же не подозреваемый, мы только время потеряем. # id: CH1_DLG_SCOLFIELD_CHOICE_P1_MIRANDA_LIE]
    -> p1_miranda_lie_1

=== p1_miranda_clarify_1 ===
Э-э-э, полагаю, адвокат мне не то чтобы нужен... (кашляет) Я просто на всякий случай спрашиваю. Я ведь не юрист, сами понимаете. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_CHOICE_P1_MIRANDA_CLARIFY_1
-> p1_miranda_clarify_2

=== p1_miranda_lie_1 ===
Если вы так считаете, спорить не буду. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_CHOICE_P1_MIRANDA_LIE_1
-> p1_miranda_clarify_2

=== p1_miranda_clarify_2 ===
Я здесь только для того, чтобы вы разобрались, что случилось с этим парнем. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_CHOICE_P1_MIRANDA_CLARIFY_2
-> p1_hub_coffee_1

===  p1_scoldield_arrest_answer_good  ===
Конечно, я всё понимаю. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_ARREST_ANSWER_GOOD
-> p1_hub_coffee_1

===  p1_scoldield_arrest_answer_suspicious  ===
Конечно, я всё понимаю. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_ARREST_ANSWER_SUSPICIOUS
-> p1_hub_coffee_1




// Coffee question (main hub 1)
=== p1_hub_coffee_1 ===
* [Будете кофе, мистер Сколфилд? # id: CH1_DLG_SCOLFIELD_CHOICE_1_P1_COFFEE_YES]
    -> p1_army_1
* [(Обойдётся) # id: CH1_DLG_SCOLFIELD_CHOICE_1_P1_COFFEE_NO]
    -> p1_feel_1
* ->
    -> p2_intro

=== p1_coffee_yes ===
Детектив Уэллер принесёт нам кофе. Вы какой любите? # speaker: anna # id: CH1_DLG_SCOLFIELD_P1_FAVOURITE_COFFEE_QUESTION
-> p1_scolfield_coffee_thanks

=== p1_scolfield_coffee_thanks ===
Большое спасибо. Мне чёрный, пожалуйста. Без сахара, без этих ваших сливок. Мы на службе пили такой. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P1_FAVOURITE_COFFEE_ANSWER
-> p1_coffee_remark

=== p1_coffee_remark ===
Знаете, я сама без порции капучино не могу даже полдня прожить. # speaker: anna # id: CH1_DLG_SCOLFIELD_P1_COFFEE_REMARK
-> p1_coffee_order

=== p1_coffee_order ===
Детектив Уэллер, будьте добры, два кофе. Один чёрный, без сахара. # speaker: anna # id: CH1_DLG_SCOLFIELD_P1_COFFEE_ORDER
-> p1_coffee_mirror

=== p1_coffee_mirror ===
Он там, да? За зеркалом? Здравствуйте, детектив! # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P1_COFFEE_MIRROR
-> p1_begin_questioning_1

=== p1_begin_questioning_1 ===
Скажу, как всё устроено. Наш разговор записывается. Вы здесь по собственной воле: вы не задержаны, обвинений вам не предъявлено, и вы можете встать и уйти в любой момент. Но я буду очень благодарна, если вы останетесь. # speaker: anna # id: CH1_DLG_SCOLFIELD_P1_BEGIN_QUESTIONING_1
-> p1_begin_questioning_2

=== p1_begin_questioning_2 ===
Вы лучше всех знали Грега и были в доме в тот день. Если кто-то и может помочь нам понять, что произошло, то это вы! # speaker: anna # id: CH1_DLG_SCOLFIELD_P1_BEGIN_QUESTIONING_2
-> p1_begin_questioning_3

=== p1_begin_questioning_3 ===
Конечно. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P1_BEGIN_QUESTIONING_3
-> p1_hub_2

=== p1_hub_2 ===
* [Если это поможет, расскажите немного о себе. Чем вы занимались до всего этого? # id: CH1_DLG_SCOLFIELD_CHOICE_1_P1_COFFEE_YES]
    -> p1_army_1
* [Как держится Тамара? # id: CH1_DLG_SCOLFIELD_CHOICE_1_P1_COFFEE_NO]
    -> p1_feel_1
* ->
    -> p2_intro

=== p1_hub ===
* [Спросить о службе в армии # id: CH1_DLG_SCOLFIELD_CHOICE_P1_HUB_PROBE_ARMY]
    -> p1_army_1
* [Спросить, как он себя чувствует # id: CH1_DLG_SCOLFIELD_CHOICE_P1_HUB_PROBE_FEELINGS]
    -> p1_feel_1
* [Перейти к делу # id: CH1_DLG_SCOLFIELD_CHOICE_P1_HUB_CONTINUE_P1]
    -> p2_intro
* ->
    -> p2_intro

=== p1_army_1 ===
Двадцать лет в форме. Впечатляет. Где служили? # speaker: anna # id: CH1_DLG_SCOLFIELD_P1_ARMY_1
-> p1_army_2

=== p1_army_2 ===
О, вот это разговор! [url=clue_army]Два тура в горячих точках[/url], слушайте, я вам расскажу — там таких, как ваши подозреваемые, только людьми не называли… # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P1_ARMY_2
-> p1_army_3

=== p1_army_3 ===
Видишь его? Ему нравится это. Ему нравится, что на него смотрят. Такие, как он, не боятся допроса — они боятся, что их не оценят по достоинству. # speaker: anna # internal: true # id: CH1_DLG_SCOLFIELD_P1_ARMY_3
-> p1_hub

=== p1_feel_1 ===
Тяжёлый, наверное, был вчерашний день. Как вы вообще… # speaker: anna # id: CH1_DLG_SCOLFIELD_P1_FEEL_1
-> p1_feel_2

=== p1_feel_2 ===
Тамара сама не своя. Я держусь ради неё. Кто-то же должен быть сильным. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P1_FEEL_2
-> p1_hub

=== p2_intro ===
Расскажите мне о бассейне. Просто опишите его — как он выглядит вечером, когда вы приходите с работы. # speaker: anna # id: CH1_DLG_SCOLFIELD_P2_INTRO
-> p2_pool

=== p2_pool ===
Хороший бассейн. [url=junk_concrete]Я сам заливал бетон под него[/url], между прочим. Тамара хотела нанять бригаду, а я сказал — зачем платить, я в армии и не такое строил. Подсветка снизу, ночью красиво светится, [url=clue_schedule]Грег там вечно торчал допоздна[/url], музыку свою слушал, я ему говорил — выключай свет, электричество не бесплатное. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P2_POOL
-> p2_knew

=== p2_knew ===
Значит, вы знали, что вечером он почти наверняка будет у бассейна. # speaker: anna # id: CH1_DLG_SCOLFIELD_P2_KNEW
-> p2_what

=== p2_what ===
Ну… да, обычно да. А что? # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P2_WHAT
-> p2_camera

=== p2_camera ===
Ничего. Продолжайте — вы сказали, залили бетон сами. Расскажите про камеру у гаража, кстати — она направлена прямо на подъездную дорожку? # speaker: anna # id: CH1_DLG_SCOLFIELD_P2_CAMERA
-> p2_camreply

=== p2_camreply ===
Да, я сам её ставил. Хорошая штука, недорогая, но картинку даёт чёткую. Записывает всё, что происходит у гаража и краем — часть двора. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P2_CAMREPLY
-> p2_observed

=== p2_observed ===
То есть вы знали точно, что ваш отъезд будет зафиксирован с точностью до минуты. # speaker: anna # id: CH1_DLG_SCOLFIELD_P2_OBSERVED
-> p2_why

=== p2_why ===
К чему вы клоните? # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P2_WHY
-> p2_hub

=== p2_hub ===
* { has_tactic("good_guy_monster") } [Злодей или ошибка # id: CH1_DLG_SCOLFIELD_CHOICE_P2_HUB_GOOD_GUY_MONSTER]
    -> p2_tactic_1
* { has_trait("NARCISSISM") } [Польстить его службе # id: CH1_DLG_SCOLFIELD_CHOICE_P2_HUB_FLATTER_SERVICE]
    ~ add_flag("flattered_scolfield")
    -> p2_flatter_1
* { get_attorney_risk() <= 30 } [Пригрозить последствиями # id: CH1_DLG_SCOLFIELD_CHOICE_P2_HUB_THREATEN]
    ~ modify_attorney_risk(35)
    ~ add_flag("threatened_scolfield")
    -> p2_threat_1
* ->
    -> p2_tactic_1

=== p2_flatter_1 ===
Двадцать лет в форме — это не строчка в личном деле. Такие люди умеют держать удар. Не каждый на вашем месте сохранил бы самообладание. # speaker: anna # id: CH1_DLG_SCOLFIELD_P2_FLATTER_1
-> p2_flatter_2

=== p2_flatter_2 ===
Вы умеете слушать. Редкость. Большинство здесь смотрят на меня как на мясо. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P2_FLATTER_2
-> p2_hub

=== p2_threat_1 ===
Эдвард, если вы будете играть в молчанку, я выйду отсюда и вернусь с ордером. И тогда у вас будет уже не беседа, а протокол. # speaker: anna # id: CH1_DLG_SCOLFIELD_P2_THREAT_1
-> p2_threat_2

=== p2_threat_2 ===
Не пугайте меня. Я двадцать лет смотрел в глаза людям, которые пытались меня запугать. Это не сработало. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P2_THREAT_2
-> p2_hub

=== p2_tactic_1 ===
Знаете, Эдвард, я сижу в этой комнате не первый год. И знаете, что я поняла? Иногда сюда приводят настоящих чудовищ — тех, кто планирует, наслаждается, не испытывает ни капли раскаяния. А иногда сюда приводят людей, которые в какой-то момент просто… запаниковали. Сделали то, что в нормальном состоянии никогда бы не сделали, а потом наделали ошибок, пытаясь всё исправить. Это очень разные люди, Эдвард. И я пока не понимаю, к какой категории отнести вас. Помогите мне понять. # speaker: anna # id: CH1_DLG_SCOLFIELD_P2_TACTIC_1
-> p2_tactic_2

=== p2_tactic_2 ===
Я… я его туда не клал, если вы об этом. То есть — не то чтобы клал. [url=confession_tampering]Я его переместил. Он уже был мёртв, ясно? Он уже не дышал, когда я до него дотронулся. Я запаниковал и затащил его в воду, чтобы было похоже, что он сам упал и захлебнулся. Это глупо, я знаю. Это было глупо.[/url] # speaker: scolfield # target_confession: confession_tampering # milestone: 1 # milestone_name: CH1_DLG_SCOLFIELD_MILESTONE_1 # id: CH1_DLG_SCOLFIELD_P2_TACTIC_2
-> p2_internal

=== p2_internal ===
Вот он, первый кирпичик. Он думает, что это самое страшное, что он мне только что сказал. Он понятия не имеет, что я только начала. # speaker: anna # internal: true # id: CH1_DLG_SCOLFIELD_P2_INTERNAL
-> p3_intro

=== p3_intro ===
Хорошо. Спасибо, что сказали правду про бассейн — это важно, Эдвард, правда важно. Теперь мне нужно, чтобы вы так же честно рассказали, что произошло до того, как вы к нему прикоснулись. Вы говорите, он уже не дышал. Что случилось перед этим? # speaker: anna # id: CH1_DLG_SCOLFIELD_P3_INTRO
-> p3_slip

=== p3_slip ===
[url=clue_slip]Несчастный случай. Он поскользнулся, ударился головой о бортик, я нашёл его уже такого.[/url] # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P3_SLIP
# beat
-> p3_forensics_hub

=== p3_forensics_hub ===
* { has_tactic("present_forensics") && has_clue("medical_discrepancy") } [Предъявить экспертизу # id: CH1_DLG_SCOLFIELD_CHOICE_P3_FORENSICS_HUB_PRESENT_FORENSICS]
    -> p3_forensics_1
* ->
    -> p3_honor_hub

=== p3_forensics_1 ===
Эдвард, я должна быть с вами честна, раз уж вы честны со мной. Судмедэксперт не нашёл следов удара о бортик. Ни синяка, ни рассечения, ничего, что совпадало бы с падением. Зато есть кое-что другое. Странгуляционные борозды на шее. Понимаете, что это значит? # speaker: anna # id: CH1_DLG_SCOLFIELD_P3_FORENSICS_1
-> p3_forensics_2

=== p3_forensics_2 ===
Это не то, что вы думаете. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P3_FORENSICS_2
-> p3_forensics_3

=== p3_forensics_3 ===
Тогда расскажите мне, что это. Потому что пока что выглядит так, будто вы душили пятнадцатилетнего мальчика, Эдвард. И я не знаю больше ни одной версии событий, которая объясняет эти борозды на шее. Может, вы знаете? # speaker: anna # id: CH1_DLG_SCOLFIELD_P3_FORENSICS_3
-> p3_honor_hub

=== p3_honor_hub ===
* { has_tactic("appeal_to_honor") } [Апелляция к чести # id: CH1_DLG_SCOLFIELD_CHOICE_P3_HONOR_HUB_APPEAL_TO_HONOR]
    -> p3_honor_1
* ->
    -> p3_honor_1

=== p3_honor_1 ===
Вы ведь уже сделали трудную часть, Эдвард. Вы сказали мне правду про бассейн, хотя могли соврать. Это говорило о том, что вы за человек. Не останавливайтесь на середине пути — это будет выглядеть хуже, чем если бы вы вообще ничего не сказали. # speaker: anna # id: CH1_DLG_SCOLFIELD_P3_HONOR_1
-> p3_honor_2

=== p3_honor_2 ===
Он меня достал, ясно? Постоянно, каждый день, это маленькое неблагодарное дерьмо — простите — доставал меня. В тот день он снова начал, я подошёл, чтобы… не знаю, встряхнуть его, что ли, привести в чувство. [url=confession_manslaughter]Схватил его за горло — не чтобы убить, просто чтобы заткнуть, чтобы он замолчал хоть на секунду. А он начал вырываться, а я… я не рассчитал. Держал слишком долго. Он обмяк, и я понял — слишком поздно. Это не было убийством. Это был несчастный случай, который начался с того, что я хотел его просто напугать.[/url] # speaker: scolfield # target_confession: confession_manslaughter # milestone: 2 # milestone_name: CH1_DLG_SCOLFIELD_MILESTONE_2 # id: CH1_DLG_SCOLFIELD_P3_HONOR_2
-> p3_internal

=== p3_internal ===
Второй кирпичик. Осталось самое сложное — доказать, что он не просто «не рассчитал». Что он хотел этого задолго до бассейна. # speaker: anna # internal: true # id: CH1_DLG_SCOLFIELD_P3_INTERNAL
-> p4_intro

=== p4_intro ===
Эдвард, вы сказали — «хотел его напугать». Скажите, вы ведь не в первый раз были в гневе из-за Грега? # speaker: anna # id: CH1_DLG_SCOLFIELD_P4_INTRO
-> p4_history

=== p4_history ===
Он трудный был парень. Я поднимал на него руку, да, признаю, не горжусь этим. Но это разные вещи — подзатыльник и то, что вы мне сейчас пытаетесь пришить. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P4_HISTORY
-> p4_threat

=== p4_threat ===
Тамара рассказала нам, что за неделю до случившегося вы сказали ей нечто вроде — цитирую — «однажды я не сдержусь, и тогда пусть пеняет на себя». Это ваши слова? # speaker: anna # id: CH1_DLG_SCOLFIELD_P4_THREAT
-> p4_defense

=== p4_defense ===
Люди говорят разное сгоряча. [url=clue_defense_trap]Это не значит, что я планировал что-то сделать.[/url] Я говорил это, да. И что? Каждый родитель в бешенстве говорит то, чего не думает. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P4_DEFENSE
-> p4_why

=== p4_why ===
Эдвард, я не спрашивала, планировали ли вы. Вы сами это сказали. Почему? # speaker: anna # id: CH1_DLG_SCOLFIELD_P4_WHY
-> p4_monster

=== p4_monster ===
…Потому что вы всё равно попытаетесь это доказать. Вам всем нужен монстр, а не человек, который сорвался. Проще посадить монстра. # speaker: scolfield # id: CH1_DLG_SCOLFIELD_P4_MONSTER
-> p4_hub

=== p4_hub ===
* { has_tactic("direct_confrontation") && has_clue("premature_defense") } [Прямая конфронтация # id: CH1_DLG_SCOLFIELD_CHOICE_P4_HUB_DIRECT_CONFRONTATION]
    -> p4_confront_1
* ->
    -> p4_force_1

=== p4_confront_1 ===
Мне не нужен монстр, Эдвард. Мне нужна правда. Вы сказали жене, что однажды не сдержитесь. За неделю до смерти Грега. Это звучит не как вспышка гнева в моменте. Это звучит как человек, который уже тогда знал, что произойдёт что-то серьёзное, и предупреждал об этом заранее. Так что случилось в тот день у бассейна? Вы правда просто «хотели напугать», или в глубине души вы уже знали, что на этот раз не остановитесь? # speaker: anna # id: CH1_DLG_SCOLFIELD_P4_CONFRONT_1
-> p4_confront_2

=== p4_confront_2 ===
[url=confession_premeditation]Я подумал об этом заранее. В то утро. Когда он опять мне нахамил за завтраком — я подумал: «сегодня, если он опять начнёт, я его заткну навсегда». Я не гнал эту мысль, Тамара уехала к сестре, дом был пустой, я знал, что если это случится сегодня — никто не помешает. А потом он начал у бассейна, и я… не сорвался. Я просто сделал то, о чём думал всё утро.[/url] # speaker: scolfield # target_confession: confession_premeditation # milestone: 3 # milestone_name: CH1_DLG_SCOLFIELD_MILESTONE_3 # id: CH1_DLG_SCOLFIELD_P4_CONFRONT_2
-> p4_final

=== p4_force_1 ===
Вы сказали жене, что однажды не сдержитесь. За неделю до смерти Грега. Я не верю в совпадения, Эдвард. И вы не верите. Скажите мне правду — не для протокола, для себя. # speaker: anna # id: CH1_DLG_SCOLFIELD_P4_FORCE_1
-> p4_force_2

=== p4_force_2 ===
[url=confession_premeditation]Я думал об этом. Утром, за завтраком. Я знал, что если он снова начнёт — я не остановлюсь. И когда он начал у бассейна, я уже не сорвался. Я просто сделал то, что решил ещё утром.[/url] # speaker: scolfield # target_confession: confession_premeditation # milestone: 3 # milestone_name: CH1_DLG_SCOLFIELD_MILESTONE_3 # id: CH1_DLG_SCOLFIELD_P4_FORCE_2
-> p4_final

=== p4_final ===
Третий кирпичик. Убийство первой степени. Он сядет до конца жизни. Я должна чувствовать облегчение. Я не чувствую ничего. # speaker: anna # internal: true # id: CH1_DLG_SCOLFIELD_P4_FINAL
-> END

=== function has_flag(flag) ===
    ~ return false

=== function has_trait(trait) ===
    // Для тестов в Inky можно временно возвращать true
    ~ return true

=== function has_tactic(tactic) ===
    ~ return true

=== function has_clue(clue) ===
    ~ return true

=== function get_attorney_risk() ===
    ~ return 0

=== function add_flag(flag) ===
    ~ return

=== function modify_attorney_risk(delta) ===
    ~ return
