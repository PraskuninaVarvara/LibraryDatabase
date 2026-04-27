using System;
using MySql.Data.MySqlClient;

namespace LibraryDatabaseApp
{
    class Program
    {
        // Строка подключения к вашей базе данных library
        static string connectionString = "server=127.0.0.1;port=3306;database=library;uid=root;pwd=;charset=utf8;";

        static void Main(string[] args)
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            bool exit = false;

            Console.WriteLine("=== СИСТЕМА УПРАВЛЕНИЯ БИБЛИОТЕКОЙ ===\n");

            while (!exit)
            {
                ShowMenu();
                Console.Write("\nВыберите действие: ");
                string choice = Console.ReadLine();

                switch (choice)
                {
                    case "1":
                        ShowAuthorsAlphabetically();
                        break;
                    case "2":
                        ShowGenresReverseOrder();
                        break;
                    case "3":
                        ShowBooksFirstFive();
                        break;
                    case "4":
                        CountAllBooks();
                        break;
                    case "5":
                        ShowUniquePublishingYears();
                        break;
                    case "6":
                        ShowEarliestBook();
                        break;
                    case "7":
                        SearchBookByID();
                        break;
                    case "8":
                        ShowAvailableCopiesCount();
                        break;
                    case "9":
                        ShowReadersRegistrationYears();
                        break;
                    case "10":
                        ShowBookWithMostCopies();
                        break;
                    case "0":
                        exit = true;
                        Console.WriteLine("Выход из программы...");
                        break;
                    default:
                        Console.WriteLine("Неверный выбор. Попробуйте снова.");
                        break;
                }

                if (!exit)
                {
                    Console.WriteLine("\nНажмите любую клавишу для продолжения...");
                    Console.ReadKey();
                    Console.Clear();
                }
            }
        }

        static void ShowMenu()
        {
            Console.WriteLine("========== ЛАБОРАТОРНАЯ РАБОТА ==========");
            Console.WriteLine("=== Задания адаптированы под БД библиотеки ===\n");

            Console.WriteLine("1.  Вывести список всех авторов, отсортированных по алфавиту");
            Console.WriteLine("2.  Вывести список всех жанров, отсортированных по коду в обратном порядке");
            Console.WriteLine("3.  Вывести список всех книг, отсортированных по названию (первые пять)");
            Console.WriteLine("4.  Вывести количество всех книг в библиотеке");
            Console.WriteLine("5.  Вывести список уникальных годов издания, отсортированных по возрастанию");
            Console.WriteLine("6.  Вывести информацию о самой старой книге");
            Console.WriteLine("7.  Вывести информацию о книге, указанной пользователем (по ID)");
            Console.WriteLine("8.  Вывести количество доступных экземпляров книг");
            Console.WriteLine("9.  Вывести список уникальных годов регистрации читателей");
            Console.WriteLine("10. Вывести книгу с наибольшим количеством экземпляров");
            Console.WriteLine("0.  Выход");
        }

        // 1. Вывести список всех авторов, отсортированных по алфавиту
        static void ShowAuthorsAlphabetically()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 1: Список всех авторов по алфавиту ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();
                string sql = "SELECT ID_author, FIO_author, country_author FROM author ORDER BY FIO_author ASC";
                MySqlCommand command = new MySqlCommand(sql, conn);
                MySqlDataReader reader = command.ExecuteReader();

                Console.WriteLine("ID\tФИО автора\t\t\tСтрана");
                Console.WriteLine("----------------------------------------------");

                while (reader.Read())
                {
                    Console.WriteLine($"{reader[0]}\t{reader[1]}\t\t{reader[2]}");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 2. Вывести список всех жанров, отсортированных по коду в обратном порядке
        static void ShowGenresReverseOrder()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 2: Список всех жанров по коду (обратный порядок) ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();
                string sql = "SELECT ID_genre, name_genre FROM genre ORDER BY ID_genre DESC";
                MySqlCommand command = new MySqlCommand(sql, conn);
                MySqlDataReader reader = command.ExecuteReader();

                Console.WriteLine("Код\tНазвание жанра");
                Console.WriteLine("---------------------");

                while (reader.Read())
                {
                    Console.WriteLine($"{reader[0]}\t{reader[1]}");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 3. Вывести список всех книг, отсортированных по названию (первые пять)
        static void ShowBooksFirstFive()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 3: Первые 5 книг по названию ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();
                string sql = "SELECT ID_book, name_book FROM books ORDER BY name_book LIMIT 5";
                MySqlCommand command = new MySqlCommand(sql, conn);
                MySqlDataReader reader = command.ExecuteReader();

                Console.WriteLine("ID\tНазвание книги");
                Console.WriteLine("------------------------------------");

                while (reader.Read())
                {
                    Console.WriteLine($"{reader[0]}\t{reader[1]}");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 4. Вывести количество всех книг в библиотеке
        static void CountAllBooks()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 4: Количество книг в библиотеке ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();

                // Общее количество книг
                string sql1 = "SELECT COUNT(*) FROM books";
                MySqlCommand command1 = new MySqlCommand(sql1, conn);
                object count = command1.ExecuteScalar();
                Console.WriteLine($"Всего книг в каталоге: {count}");

                // Количество экземпляров
                string sql2 = "SELECT COUNT(*) FROM a_copy_of_book";
                MySqlCommand command2 = new MySqlCommand(sql2, conn);
                object copies = command2.ExecuteScalar();
                Console.WriteLine($"Всего экземпляров книг: {copies}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 5. Вывести список уникальных годов издания, отсортированных по возрастанию
        static void ShowUniquePublishingYears()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 5: Уникальные годы издания книг ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();
                string sql = "SELECT DISTINCT YEAR(date_public) FROM books ORDER BY YEAR(date_public) ASC";
                MySqlCommand command = new MySqlCommand(sql, conn);
                MySqlDataReader reader = command.ExecuteReader();

                Console.WriteLine("Год издания");
                Console.WriteLine("-----------");

                while (reader.Read())
                {
                    Console.WriteLine($"{reader[0]}");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 6. Вывести информацию о самой старой книге
        static void ShowEarliestBook()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 6: Самая старая книга ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();
                string sql = @"
                    SELECT b.name_book, a.FIO_author, b.date_public 
                    FROM books b 
                    JOIN author a ON b.ID_author = a.ID_author 
                    WHERE b.date_public = (SELECT MIN(date_public) FROM books)";

                MySqlCommand command = new MySqlCommand(sql, conn);
                MySqlDataReader reader = command.ExecuteReader();

                if (reader.Read())
                {
                    Console.WriteLine($"Название: {reader[0]}");
                    Console.WriteLine($"Автор: {reader[1]}");
                    Console.WriteLine($"Дата издания: {Convert.ToDateTime(reader[2]).ToString("dd.MM.yyyy")}");
                }
                else
                {
                    Console.WriteLine("Книги не найдены");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 7. Вывести информацию о книге, указанной пользователем (по ID)
        static void SearchBookByID()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 7: Поиск книги по ID ===\n");

            Console.Write("Введите ID книги: ");
            string input = Console.ReadLine();

            if (!int.TryParse(input, out int bookId))
            {
                Console.WriteLine("Ошибка: Введите корректный ID (число)");
                return;
            }

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();
                string sql = @"
                    SELECT b.ID_book, b.name_book, a.FIO_author, g.name_genre, b.date_public 
                    FROM books b 
                    JOIN author a ON b.ID_author = a.ID_author 
                    JOIN genre g ON b.ID_genre = g.ID_genre 
                    WHERE b.ID_book = @bookId";

                MySqlCommand command = new MySqlCommand(sql, conn);
                command.Parameters.AddWithValue("@bookId", bookId);
                MySqlDataReader reader = command.ExecuteReader();

                if (reader.Read())
                {
                    Console.WriteLine($"\nНайдена книга:");
                    Console.WriteLine($"ID: {reader[0]}");
                    Console.WriteLine($"Название: {reader[1]}");
                    Console.WriteLine($"Автор: {reader[2]}");
                    Console.WriteLine($"Жанр: {reader[3]}");
                    Console.WriteLine($"Дата издания: {Convert.ToDateTime(reader[4]).ToString("dd.MM.yyyy")}");
                }
                else
                {
                    Console.WriteLine($"Книга с ID={bookId} не найдена");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 8. Вывести количество доступных экземпляров книг
        static void ShowAvailableCopiesCount()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 8: Доступные экземпляры книг ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();

                // Всего экземпляров
                string sql1 = "SELECT COUNT(*) FROM a_copy_of_book";
                MySqlCommand command1 = new MySqlCommand(sql1, conn);
                object total = command1.ExecuteScalar();
                Console.WriteLine($"Всего экземпляров: {total}");

                // Доступных экземпляров
                string sql2 = "SELECT COUNT(*) FROM a_copy_of_book WHERE condition_copy = 'Доступна'";
                MySqlCommand command2 = new MySqlCommand(sql2, conn);
                object available = command2.ExecuteScalar();
                Console.WriteLine($"Доступно для выдачи: {available}");

                // Выданных экземпляров
                string sql3 = "SELECT COUNT(*) FROM a_copy_of_book WHERE condition_copy = 'Выдана'";
                MySqlCommand command3 = new MySqlCommand(sql3, conn);
                object borrowed = command3.ExecuteScalar();
                Console.WriteLine($"Выдано читателям: {borrowed}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 9. Вывести список уникальных годов регистрации читателей
        static void ShowReadersRegistrationYears()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 9: Годы регистрации читателей ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();
                string sql = "SELECT DISTINCT YEAR(getting_rticket) FROM readers ORDER BY YEAR(getting_rticket) DESC";
                MySqlCommand command = new MySqlCommand(sql, conn);
                MySqlDataReader reader = command.ExecuteReader();

                Console.WriteLine("Год регистрации");
                Console.WriteLine("---------------");

                while (reader.Read())
                {
                    Console.WriteLine($"{reader[0]}");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }

        // 10. Вывести книгу с наибольшим количеством экземпляров
        static void ShowBookWithMostCopies()
        {
            Console.WriteLine("\n=== ЗАДАНИЕ 10: Книга с наибольшим количеством экземпляров ===\n");

            MySqlConnection conn = new MySqlConnection(connectionString);

            try
            {
                conn.Open();
                string sql = @"
                    SELECT b.name_book, a.FIO_author, COUNT(c.ID_copy) as copies_count
                    FROM books b
                    JOIN author a ON b.ID_author = a.ID_author
                    JOIN a_copy_of_book c ON b.ID_book = c.ID_book
                    GROUP BY b.ID_book, b.name_book, a.FIO_author
                    ORDER BY copies_count DESC
                    LIMIT 1";

                MySqlCommand command = new MySqlCommand(sql, conn);
                MySqlDataReader reader = command.ExecuteReader();

                if (reader.Read())
                {
                    Console.WriteLine($"Название: {reader[0]}");
                    Console.WriteLine($"Автор: {reader[1]}");
                    Console.WriteLine($"Количество экземпляров: {reader[2]}");
                }
                else
                {
                    Console.WriteLine("Данные не найдены");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка: {ex.Message}");
            }
            finally
            {
                conn.Close();
            }
        }
    }
}