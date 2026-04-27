-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Время создания: Дек 02 2025 г., 13:23
-- Версия сервера: 10.4.32-MariaDB
-- Версия PHP: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `library`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `выдать_книгу` (IN `id_экземпляра` INT, IN `id_читателя` INT, IN `id_сотрудника` INT, IN `срок_выдачи` INT)   BEGIN
    -- Объявляем переменные
    DECLARE дата_возврата DATE;
    DECLARE статус_книги VARCHAR(50);
    DECLARE название_книги VARCHAR(255);
    DECLARE имя_читателя VARCHAR(255);
    DECLARE имя_сотрудника VARCHAR(255);
    DECLARE книга_выдана BOOLEAN DEFAULT FALSE;
    
    -- 1. ПРОВЕРКА СУЩЕСТВОВАНИЯ ДАННЫХ
    
    -- Проверяем, существует ли экземпляр книги
    SELECT COUNT(*) INTO книга_выдана 
    FROM a_copy_of_book 
    WHERE ID_copy = id_экземпляра;
    
    IF книга_выдана = 0 THEN
        SELECT 'ОШИБКА: Экземпляр книги не найден' AS результат;
    ELSE
        -- 2. ПРОВЕРКА ДОСТУПНОСТИ КНИГИ
        
        -- Получаем текущий статус книги
        SELECT condition_copy INTO статус_книги
        FROM a_copy_of_book 
        WHERE ID_copy = id_экземпляра;
        
        IF статус_книги != 'Доступна' THEN
            SELECT CONCAT('ОШИБКА: Книга не доступна. Статус: ', статус_книги) AS результат;
        ELSE
            -- 3. ПРОВЕРКА СУЩЕСТВОВАНИЯ ЧИТАТЕЛЯ И СОТРУДНИКА
            
            IF NOT EXISTS (SELECT 1 FROM readers WHERE ID_reader = id_читателя) THEN
                SELECT 'ОШИБКА: Читатель не найден' AS результат;
            ELSEIF NOT EXISTS (SELECT 1 FROM staff WHERE ID_staff = id_сотрудника) THEN
                SELECT 'ОШИБКА: Сотрудник не найден' AS результат;
            ELSE
                -- 4. РАСЧЕТ ДАТЫ ВОЗВРАТА
                SET дата_возврата = DATE_ADD(CURDATE(), INTERVAL срок_выдачи DAY);
                
                -- 5. ПОЛУЧАЕМ ДОПОЛНИТЕЛЬНУЮ ИНФОРМАЦИЮ
                
                -- Название книги
                SELECT b.name_book INTO название_книги
                FROM books b
                JOIN a_copy_of_book c ON b.ID_book = c.ID_book
                WHERE c.ID_copy = id_экземпляра;
                
                -- Имя читателя
                SELECT FIO_reader INTO имя_читателя
                FROM readers 
                WHERE ID_reader = id_читателя;
                
                -- Имя сотрудника
                SELECT FIO_staff INTO имя_сотрудника
                FROM staff 
                WHERE ID_staff = id_сотрудника;
                
                -- 6. ВЫПОЛНЯЕМ ОПЕРАЦИЮ ВЫДАЧИ
                
                -- Начинаем транзакцию для безопасности
                START TRANSACTION;
                
                -- 6.1. Меняем статус книги на "Выдана"
                UPDATE a_copy_of_book 
                SET condition_copy = 'Выдана' 
                WHERE ID_copy = id_экземпляра;
                
                -- 6.2. Создаем запись о выдаче в журнал
                INSERT INTO book_distribution 
                (ID_copy, ID_reader, ID_staff, date_taken, date_return)
                VALUES 
                (id_экземпляра, id_читателя, id_сотрудника, CURDATE(), дата_возврата);
                
                -- Получаем ID созданной записи
                SET @id_записи = LAST_INSERT_ID();
                
                -- Завершаем транзакцию
                COMMIT;
                
                -- 7. ВОЗВРАЩАЕМ РЕЗУЛЬТАТ
                SELECT 
                    'КНИГА УСПЕШНО ВЫДАНА' AS статус,
                    название_книги AS книга,
                    имя_читателя AS читатель,
                    имя_сотрудника AS сотрудник,
                    CURDATE() AS дата_выдачи,
                    дата_возврата AS вернуть_до,
                    CONCAT(срок_выдачи, ' дней') AS срок_выдачи,
                    @id_записи AS id_записи_в_журнале;
            END IF;
        END IF;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `найти_книги_автора` (IN `имя_автора` VARCHAR(100))   BEGIN
    -- Простой SELECT запрос для поиска книг
    SELECT 
        b.ID_book AS 'ID_книги',
        b.name_book AS 'Название_книги',
        a.FIO_author AS 'Автор',
        g.name_genre AS 'Жанр',
        p.name_publishing AS 'Издательство',
        YEAR(b.date_public) AS 'Год_издания'
    FROM books b
    JOIN author a ON b.ID_author = a.ID_author
    JOIN genre g ON b.ID_genre = g.ID_genre
    JOIN publishing p ON b.ID_publishing = p.ID_publishing
    WHERE a.FIO_author LIKE CONCAT('%', имя_автора, '%')
    ORDER BY b.name_book;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `простой_возврат` (IN `запись_id` INT)   BEGIN
    DECLARE книга_id INT;
    
    -- Получаем ID книги
    SELECT ID_copy INTO книга_id 
    FROM book_distribution 
    WHERE ID_distribution = запись_id;
    
    IF книга_id IS NULL THEN
        SELECT 'Запись не найдена' AS результат;
    ELSE
        -- Отмечаем возврат
        UPDATE book_distribution 
        SET date_return = CURDATE() 
        WHERE ID_distribution = запись_id;
        
        -- Меняем статус книги
        UPDATE a_copy_of_book 
        SET condition_copy = 'Доступна' 
        WHERE ID_copy = книга_id;
        
        SELECT 
            'Книга возвращена' AS результат,
            CURDATE() AS 'дата возврата';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `author`
--

CREATE TABLE `author` (
  `ID_author` int(11) NOT NULL,
  `FIO_author` varchar(25) NOT NULL,
  `country_author` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Дамп данных таблицы `author`
--

INSERT INTO `author` (`ID_author`, `FIO_author`, `country_author`) VALUES
(1, 'А.С.Пушкин', 'Россия'),
(2, 'М.Ю.Лермонтов', 'Россия'),
(3, 'Н.В.Гоголь', 'Россия'),
(4, 'Л.Н.Толстой', 'Россия'),
(5, 'С.А.Есенин', 'Россия'),
(6, 'В.В.Маяковский', 'Россия'),
(7, 'Ф.М.Достоевский', 'Россия'),
(8, 'И.А.Бунин', 'Россия'),
(9, 'Р.Д.Брэдбери', 'США'),
(10, 'Д.Р.Фаулз', 'Великобритания'),
(11, 'Э.Берджесс', 'Великобритания'),
(12, 'Д.Остен', 'Великобритания'),
(13, 'Э.Хемингуэль', 'США'),
(14, 'Харуки Мураками', 'Япония');

--
-- Триггеры `author`
--
DELIMITER $$
CREATE TRIGGER `prevent_author_deletion_if_books_exist` BEFORE DELETE ON `author` FOR EACH ROW BEGIN
    DECLARE books_count INT;
    
    -- Считаем книги автора
    SELECT COUNT(*) INTO books_count
    FROM books
    WHERE ID_author = OLD.ID_author;
    
    -- Если есть книги, запрещаем удаление
    IF books_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Нельзя удалить автора, у которого есть книги в библиотеке. Сначала удалите все его книги.';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `a_copy_of_book`
--

CREATE TABLE `a_copy_of_book` (
  `ID_copy` int(11) NOT NULL,
  `ID_book` int(11) NOT NULL,
  `condition_copy` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Дамп данных таблицы `a_copy_of_book`
--

INSERT INTO `a_copy_of_book` (`ID_copy`, `ID_book`, `condition_copy`) VALUES
(1, 1, 'Доступна'),
(2, 2, 'Доступна'),
(3, 3, 'Доступна'),
(4, 4, 'В ремонте'),
(5, 5, 'Выдана'),
(6, 6, 'Выдана'),
(7, 7, 'Выдана'),
(8, 8, 'Доступна'),
(9, 9, 'Выдана'),
(10, 10, 'Доступна'),
(11, 11, 'В ремонте'),
(12, 12, 'В ремонте'),
(13, 13, 'Доступна'),
(14, 14, 'Выдана'),
(15, 15, 'Выдана'),
(16, 16, 'Доступна'),
(17, 17, 'В ремонте'),
(18, 18, 'Доступна'),
(19, 19, 'Доступна');

-- --------------------------------------------------------

--
-- Структура таблицы `books`
--

CREATE TABLE `books` (
  `ID_book` int(11) NOT NULL,
  `name_book` varchar(25) NOT NULL,
  `ID_author` int(11) NOT NULL,
  `ID_publishing` int(11) NOT NULL,
  `ID_genre` int(11) NOT NULL,
  `date_public` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Дамп данных таблицы `books`
--

INSERT INTO `books` (`ID_book`, `name_book`, `ID_author`, `ID_publishing`, `ID_genre`, `date_public`) VALUES
(1, 'Капитанская дочка', 1, 1, 4, '1836-11-18'),
(2, 'Герой нашего времени', 2, 1, 5, '1840-10-08'),
(3, 'Вий', 3, 5, 1, '1835-05-13'),
(4, 'Преступление и наказание', 7, 2, 8, '1866-04-26'),
(5, 'Война и мир. Том 1', 4, 2, 9, '1867-07-19'),
(6, 'Война и мир. Том 2', 4, 2, 9, '1868-03-20'),
(7, 'Война и мир. Том 3', 4, 2, 9, '1869-10-01'),
(8, 'Война и мир. Том 4', 4, 2, 9, '1869-12-20'),
(9, 'Белая берёза под моим окн', 5, 1, 10, '1914-01-31'),
(10, 'Облако в штанах', 6, 3, 11, '1915-08-11'),
(11, 'Господин из Сан-Франциско', 8, 2, 12, '1915-02-15'),
(12, '451 градус по Фаренгейту', 9, 3, 2, '1953-03-05'),
(13, 'И грянул гром', 9, 2, 2, '1952-06-28'),
(14, 'Коллекционер', 10, 1, 3, '1963-02-10'),
(15, 'Заводной апельсин', 11, 2, 13, '1962-05-16'),
(16, 'Гордость и предубеждение', 12, 1, 4, '1813-01-28'),
(17, 'Старик и море', 13, 3, 14, '1952-11-02'),
(18, 'Норвежский лес', 14, 1, 4, '1987-12-03'),
(19, 'Кафка на пляже', 14, 1, 15, '2002-09-10');

-- --------------------------------------------------------

--
-- Структура таблицы `book_distribution`
--

CREATE TABLE `book_distribution` (
  `ID_distribution` int(11) NOT NULL,
  `ID_copy` int(11) NOT NULL,
  `ID_reader` int(11) NOT NULL,
  `ID_staff` int(11) NOT NULL,
  `date_taken` date NOT NULL,
  `date_return` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Дамп данных таблицы `book_distribution`
--

INSERT INTO `book_distribution` (`ID_distribution`, `ID_copy`, `ID_reader`, `ID_staff`, `date_taken`, `date_return`) VALUES
(1, 2, 1, 2, '2011-12-01', '2011-12-30'),
(2, 3, 1, 1, '2013-01-01', '2013-03-01'),
(3, 1, 3, 3, '2019-02-02', '2025-12-02'),
(4, 5, 4, 3, '2025-10-20', NULL),
(5, 6, 4, 3, '2024-10-20', NULL),
(6, 7, 6, 1, '2025-01-05', NULL),
(7, 8, 5, 4, '2001-10-02', '2001-12-01'),
(8, 14, 2, 3, '2025-06-04', NULL),
(9, 15, 7, 1, '2020-04-15', NULL),
(10, 16, 1, 4, '2024-05-20', '2024-05-30'),
(11, 9, 1, 1, '2024-05-20', '2024-05-25'),
(12, 10, 1, 1, '2024-05-21', '2024-05-26'),
(13, 9, 3, 2, '2025-12-02', '2025-12-16');

--
-- Триггеры `book_distribution`
--
DELIMITER $$
CREATE TRIGGER `check_return_date_before_insert` BEFORE INSERT ON `book_distribution` FOR EACH ROW BEGIN
    IF NEW.date_return IS NOT NULL AND NEW.date_return < NEW.date_taken THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ошибка: Дата возврата не может быть раньше даты выдачи';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_book_condition_on_return` BEFORE UPDATE ON `book_distribution` FOR EACH ROW BEGIN
    -- Проверяем, что книга возвращается (проставляется date_return)
    IF NEW.date_return IS NOT NULL AND OLD.date_return IS NULL THEN
        -- Меняем статус экземпляра книги с "Выдана" на "Доступна"
        UPDATE a_copy_of_book
        SET condition_copy = 'Доступна'
        WHERE ID_copy = NEW.ID_copy AND condition_copy = 'Выдана';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `genre`
--

CREATE TABLE `genre` (
  `ID_genre` int(11) NOT NULL,
  `name_genre` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Дамп данных таблицы `genre`
--

INSERT INTO `genre` (`ID_genre`, `name_genre`) VALUES
(1, 'Мистика'),
(2, 'Научная фантастика'),
(3, 'Детектив'),
(4, 'Романтика'),
(5, 'Приключения'),
(6, 'Ужасы'),
(7, 'Биография'),
(8, 'Драма'),
(9, 'Роман-эпопея'),
(10, 'Лирический стих'),
(11, 'Поэма'),
(12, 'Новелла'),
(13, 'Антиутопия'),
(14, 'Повесть-притча'),
(15, 'Психология');

-- --------------------------------------------------------

--
-- Структура таблицы `publishing`
--

CREATE TABLE `publishing` (
  `ID_publishing` int(11) NOT NULL,
  `name_publishing` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Дамп данных таблицы `publishing`
--

INSERT INTO `publishing` (`ID_publishing`, `name_publishing`) VALUES
(1, 'Литрес'),
(2, 'Эксмо'),
(3, 'Магистраль'),
(4, 'Феникс'),
(5, 'Просвещение'),
(6, 'Росмэн');

-- --------------------------------------------------------

--
-- Структура таблицы `readers`
--

CREATE TABLE `readers` (
  `ID_reader` int(11) NOT NULL,
  `FIO_reader` varchar(30) NOT NULL,
  `email_reader` varchar(30) NOT NULL,
  `getting_rticket` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Дамп данных таблицы `readers`
--

INSERT INTO `readers` (`ID_reader`, `FIO_reader`, `email_reader`, `getting_rticket`) VALUES
(1, 'Криворуков А.С.', 'krivoy@gmail.com', '2011-11-11'),
(2, 'Руколицов П.М.', 'handVrD@yandex.ru', '2025-06-03'),
(3, 'Лебедев И.В.', 'leb_i@mail.ru', '2019-02-02'),
(4, 'Павлов А.Т.', 'pet_at@gmail.com', '2016-10-19'),
(5, 'Попова С.К.', 'popov_sk@yandex.ru', '2000-02-01'),
(6, 'Петрова А.А.', 'paapw@gmail.com', '2017-07-17'),
(7, 'Соколов Т.М.', 'sokol_T@yandex.ru', '2020-02-15');

-- --------------------------------------------------------

--
-- Структура таблицы `staff`
--

CREATE TABLE `staff` (
  `ID_staff` int(11) NOT NULL,
  `FIO_staff` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Дамп данных таблицы `staff`
--

INSERT INTO `staff` (`ID_staff`, `FIO_staff`) VALUES
(1, 'Новикова А.М'),
(2, 'Степанов М.М.'),
(3, 'Егорова Л.А.'),
(4, 'Васильева В.В.');

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `author`
--
ALTER TABLE `author`
  ADD PRIMARY KEY (`ID_author`);

--
-- Индексы таблицы `a_copy_of_book`
--
ALTER TABLE `a_copy_of_book`
  ADD PRIMARY KEY (`ID_copy`),
  ADD KEY `ID_book` (`ID_book`);

--
-- Индексы таблицы `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`ID_book`),
  ADD KEY `ID_author` (`ID_author`),
  ADD KEY `ID_publishing` (`ID_publishing`),
  ADD KEY `ID_genre` (`ID_genre`);

--
-- Индексы таблицы `book_distribution`
--
ALTER TABLE `book_distribution`
  ADD PRIMARY KEY (`ID_distribution`),
  ADD KEY `ID_copy` (`ID_copy`),
  ADD KEY `ID_reader` (`ID_reader`),
  ADD KEY `ID_staff` (`ID_staff`);

--
-- Индексы таблицы `genre`
--
ALTER TABLE `genre`
  ADD PRIMARY KEY (`ID_genre`);

--
-- Индексы таблицы `publishing`
--
ALTER TABLE `publishing`
  ADD PRIMARY KEY (`ID_publishing`);

--
-- Индексы таблицы `readers`
--
ALTER TABLE `readers`
  ADD PRIMARY KEY (`ID_reader`);

--
-- Индексы таблицы `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`ID_staff`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `author`
--
ALTER TABLE `author`
  MODIFY `ID_author` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT для таблицы `a_copy_of_book`
--
ALTER TABLE `a_copy_of_book`
  MODIFY `ID_copy` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT для таблицы `books`
--
ALTER TABLE `books`
  MODIFY `ID_book` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT для таблицы `book_distribution`
--
ALTER TABLE `book_distribution`
  MODIFY `ID_distribution` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT для таблицы `genre`
--
ALTER TABLE `genre`
  MODIFY `ID_genre` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT для таблицы `publishing`
--
ALTER TABLE `publishing`
  MODIFY `ID_publishing` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT для таблицы `readers`
--
ALTER TABLE `readers`
  MODIFY `ID_reader` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT для таблицы `staff`
--
ALTER TABLE `staff`
  MODIFY `ID_staff` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
