КДЗ номер 37
-
Я сделал набросок бд в папке sql_scheme

Бизнес домен:
5 основных сущностей:
User - пользователь

Like - запрос одного User к другому на знакомство, 
при изменение поля agreed на true создается сущность Match.
Связан с users внешними ключами from_whom и to_whom.

Match - событие знакомства,
по сути чат, дружба.
Связан с users внешними ключами from_whom и to_whom

Message - сообщение пользователей в Match.
Связан с matches внещними ключом match_id

get_recommendation - процедура возвращающая случайного человека противоположного пола
