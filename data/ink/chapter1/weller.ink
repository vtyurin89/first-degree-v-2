EXTERNAL has_flag(flag)
EXTERNAL has_case_file()
EXTERNAL add_flag(flag)

-> start

=== start ===
// { has_flag("weller_briefing_done"):
//     -> return_intro
// }
-> weller_1

=== return_intro ===
Ну что, готова? # speaker: weller # id: CH1_DLG_WELLER_RETURN_INTRO
-> check_case_file

=== weller_1 ===
Надо же, Кроуфорд, ты выглядишь… почти как человек. Это прогресс, я считаю. # speaker: weller # id: CH1_DLG_WELLER_1
-> anna_1

=== anna_1 ===
Спасибо, Мартин, очень тронута. # speaker: anna # id: CH1_DLG_WELLER_ANNA_1
-> weller_2

=== weller_2 ===
Анна, я нашёл тебя вчера в баре, где ты напилась и вела себя как больная. Господи, хорошо, что Гринуэй не видел тебя в таком виде! Ты точно сможешь работать? # speaker: weller # id: CH1_DLG_WELLER_2
-> anna_2

=== anna_2 ===
Постараюсь. Хотя голова трещит... Нужно показать старику, что он не просто так меня держит в отделе допросов. Извини, что доставила проблем. # speaker: anna # id: CH1_DLG_WELLER_ANNA_2
-> weller_3

=== weller_3 ===
Знаешь, что было бы с любым другим следователем в отделе после третьей такой выходки за месяц? # speaker: weller # id: CH1_DLG_WELLER_3
-> anna_3

=== anna_3 ===
Дай угадаю. Его бы на хер уволили. А все вокруг вздохнули бы с облегчением. # speaker: anna # id: CH1_DLG_WELLER_ANNA_3
-> weller_4

=== weller_4 ===
... # speaker: weller # id: CH1_DLG_WELLER_4
-> weller_5

=== weller_5 ===
Ладно, я не собирался читать нотации. Давай работать. Подозреваемый ждёт, пора начинать допрос. # speaker: weller # id: CH1_DLG_WELLER_5
-> weller_choice_1

=== weller_choice_1 ===
* [Еще раз вкратце расскажи, что мы знаем о подозреваемом. # id: CH1_DLG_WELLER_CHOICE_SUSPECT_QUESTION]
    -> answer_suspect_1
* [Может, быстренько покурим перед допросом? # id: CH1_DLG_WELLER_CHOICE_SMOKE_QUESTION]
    ~ add_flag("asked_about_smoking")
    -> answer_smoke_1
* [От меня сильно пахнет? Я, вроде, привела себя в порядок... # id: CH1_DLG_WELLER_CHOICE_STENCH_QUESTION]
    ~ add_flag("asked_about_stench")
    -> answer_stench_1

=== answer_smoke_1 ===
Слушай, этот мужик здесь добровольно, ордера на его арест у нас нет. Если он решит, что мы тянем время, то просто свалит через парадный вход, и никто его не остановит. # speaker: weller # id: CH1_DLG_WELLER_ANSWER_SMOKE_1
-> answer_smoke_2

=== answer_smoke_2 ===
Покуришь, когда побеседуешь с ним. # speaker: weller # id: CH1_DLG_WELLER_ANSWER_SMOKE_2
-> answer_smoke_3

=== answer_smoke_3 ===
Ладно-ладно... # speaker: anna # id: CH1_DLG_WELLER_ANSWER_SMOKE_3
-> weller_choice_1

=== answer_stench_1 ===
Перегаром немного несёт. Я оставил на столе жвачку с ментолом. Не благодари. # speaker: weller # id: CH1_DLG_WELLER_ANSWER_STENCH_1
-> answer_stench_2

=== answer_stench_2 ===
Мой герой! # speaker: anna # id: CH1_DLG_WELLER_ANSWER_STENCH_2
-> weller_choice_1

=== answer_suspect_1 ===
Ты ведь читала материалы дела? Они лежат на столе. # speaker: weller # id: CH1_DLG_WELLER_ANSWER_SUSPECT_1
-> answer_suspect_2

=== answer_suspect_2 ===
Зовут Эдвард Сколфилд. Бывший военный, сорок три года. Двадцать лет службы, вышел на пенсию три года назад. Его жену зовут Тамара, пасынка звали Грег, ему было пятнадцать. # speaker: weller # id: CH1_DLG_WELLER_ANSWER_SUSPECT_2
-> answer_suspect_3

=== answer_suspect_3 ===
Эдвард и Грег терпеть друг друга не могли. Соседи регулярно слышали крики и брань, а вчера вечером Грега нашли плавающим в бассейне. Эдвард уверял, что в момент убийства был в магазине, но время не совсем совпадает. То есть железного алиби у него нет. А в таких делах сама понимаешь как бывает... # speaker: weller # id: CH1_DLG_WELLER_ANSWER_SUSPECT_3
-> anna_suspect_comment_1

=== anna_suspect_comment_1 ===
Бритва Окамма. Скорее всего, убийца - член семьи. И наверняка тот, который первый попал под подозрение. # speaker: anna # id: CH1_DLG_WELLER_ANNA_SUSPECT_COMMENT_1
-> answer_suspect_4

=== answer_suspect_4 ===
Бинго! # speaker: weller # id: CH1_DLG_WELLER_ANSWER_SUSPECT_4
-> ready_for_questioning_1

=== ready_for_questioning_1 ===
Готова начать допрос, Кроуфорд? Если тебе нужно еще несколько минут, чтобы посмотреть материалы на столе или выпить кофе, то я могу подождать. # speaker: weller # id: CH1_DLG_WELLER_READY_FOR_QUESTIONING_1
-> check_case_file

=== check_case_file ===
{ has_case_file():
    -> weller_choice_2
}
-> ready_for_questioning_2

=== ready_for_questioning_2 ===
Обязательно возьми со стола материалы дела. Их ты сможешь посмотреть в любой момент даже в допросной, но все остальные улики лучше изучить сейчас, ведь в допросную их взять не получится. # speaker: weller # id: CH1_DLG_WELLER_READY_FOR_QUESTIONING_2
-> ready_for_questioning_3

=== ready_for_questioning_3 ===
В допросной нужно быть во всеоружии! Тебе понадобится вся энергия, которая у тебя есть. # speaker: weller # id: CH1_DLG_WELLER_READY_FOR_QUESTIONING_3
-> weller_choice_2

=== weller_choice_2 ===
* [Думаю, я готова. # id: CH1_DLG_WELLER_CHOICE_READY_1]
    -> ready_check_scolfield
* [Мне нужно еще пару минут на подготовку. # id: CH1_DLG_WELLER_CHOICE_NOT_READY_1]
    -> not_ready_weller

=== ready_check_scolfield ===
{ has_case_file():
    -> ready_weller_1
}
-> scolfield_file_missing

=== scolfield_file_missing ===
Постой, возьми материалы дела со стола. # speaker: weller # id: CH1_SCOLFIELD_FILE_MISSING
-> scolfield_file_missing_reply

=== scolfield_file_missing_reply ===
Ладно, сейчас... # speaker: anna # id: CH1_SCOLFIELD_FILE_MISSING_REPLY
-> END

=== ready_weller_1 ===
Хорошо. В какую допросную комнату отвести Сколфилда? В аквариум или в плюшевую? # speaker: weller # id: CH1_DLG_WELLER_READY_1
-> ready_weller_2

=== ready_weller_2 ===
В аквариуме ему будет неуютно, и тебе проще будет давить на него. В плюшевой комнате он расслабится, потому что будет чувствовать себя просто свидетелем. # speaker: weller # id: CH1_DLG_WELLER_READY_2
-> weller_choice_3

=== weller_choice_3 ===
* [Допрошу его в аквариуме. # id: CH1_DLG_WELLER_CHOICE_TANK]
    -> last_line_weller
* [Допрошу его в плюшевой комнате. # id: CH1_DLG_WELLER_CHOICE_VELVET]
    -> last_line_weller

=== last_line_weller ===
Конечно. Я буду в аппаратной, если что. Задай ему жару, Кроуфорд! # speaker: weller # id: CH1_DLG_WELLER_LAST_LINE_WELLER
-> END

=== not_ready_weller ===
Дай знать, когда будешь готова, Кроуфорд. # speaker: weller # id: CH1_DLG_WELLER_NOT_READY_WELLER
-> END

=== function has_flag(flag) ===
    // Проверяем, совпадает ли переданный флаг с нужным нам
    { flag == "weller_briefing_done":
        ~ return true
    }
    // Если условие выше не сработало, код идёт дальше и возвращает false
    ~ return false
    
=== function has_case_file() ===
    ~ return true
