Перем РежимОтладки;

Функция ОбработатьФайлы(Каталог)

	Кроп = Новый Структура("Ширина,Высота,СмещениеХ,СмещениеУ");
	Кроп.Ширина		= 650;
	Кроп.Высота		= 300;
	Кроп.СмещениеХ	= 2300 - Кроп.Ширина;
	Кроп.СмещениеУ	= 0;// 3200 - Кроп.Высота;

	КаталогОбработки = ОбъединитьПути(Каталог, "process");
	ФайлКаталогОбработки = Новый Файл(КаталогОбработки);
	Если Не ФайлКаталогОбработки.Существует() Тогда
		СоздатьКаталог(КаталогОбработки);
	Иначе
		УдалитьФайлы(КаталогОбработки, "*");
	КонецЕсли;

	МассивФайлов = НайтиФайлы(Каталог, "*.jpg");
	Для каждого ФайлКартинки из МассивФайлов Цикл

		СообщениеОтладки("Обрабатывается: " + ФайлКартинки.ПолноеИмя);

		// Кропнуть во временный файл часть изображения, где потенциально располагается номер стиха:
		//	convert -crop 2300x3200+74+32 IMG_20180903_015548.jpg test.jpg

		ВремПутьРезультатаКропа = ОбъединитьПути(КаталогОбработки, ФайлКартинки.Имя + ".crop.jpg");
		
		КомандаКропа = СтрШаблон(
			"convert -crop %1x%2+%3+%4 %5 %6", 
			Кроп.Ширина,
			Кроп.Высота,
			Кроп.СмещениеХ,
			Кроп.СмещениеУ,
			ФайлКартинки.ПолноеИмя,
			ВремПутьРезультатаКропа
		);
		ЗапуститьПриложение(КомандаКропа, КаталогОбработки, Истина);

		Если Не ФайлСуществует(ВремПутьРезультатаКропа) Тогда
			СообщениеОтладки("--> Не удалось выполнить кроп части изображения с номером стиха");
			Продолжить;
		КонецЕсли;

		ВремПутьРезультатаМонохром = ОбъединитьПути(КаталогОбработки, ФайлКартинки.Имя + ".mnchrm.jpg");

		// Переводим в монохром
		КомандаМонохром = СтрШаблон(
			"convert %1 -colorspace gray -auto-level -threshold %2 %3",
			ВремПутьРезультатаКропа,
			"20%",
			ВремПутьРезультатаМонохром
		);
		ВыполнитьКоманду(КомандаМонохром);

		Если Не ФайлСуществует(ВремПутьРезультатаМонохром) Тогда
			СообщениеОтладки("--> Не удалось выполнить перевода изображения в ч/б");
			Продолжить;
		КонецЕсли;


		ПутьКФайлуДляРаспознавания = ВремПутьРезультатаКропа; // ВремПутьРезультатаМонохром;

		// Распознать номер:
		// 	tesseract --tessdata-dir /usr/share/tesseract-ocr/tessdata ПутьКВременномуФайлу /tmp/test-result.txt

		ВремПутьРезультатаРаспознавания = ОбъединитьПути(КаталогОбработки, ФайлКартинки.Имя + ".ocr");

		КомандаТессеракт = СтрШаблон(
			"tesseract --tessdata-dir /home/kuntashov/poetry/tools/tessdata_best/ %1 %2 -l eng",
			ПутьКФайлуДляРаспознавания,
			ВремПутьРезультатаРаспознавания
		);

		ВыполнитьКоманду(КомандаТессеракт);

		//Сообщить(КомандаТессеракт);
		//ЗапуститьПриложение(КомандаТессеракт, КаталогОбработки, Истина);
		
		// tesseract к результирующему файлу добавляет расширение txt
		ВремПутьРезультатаРаспознавания = ВремПутьРезультатаРаспознавания + ".txt";

		Если Не ФайлСуществует(ВремПутьРезультатаРаспознавания) Тогда
			СообщениеОтладки("--> Не удалось распознать файл с номером стиха");
			Продолжить;
		КонецЕсли;

		НомерСтиха = Неопределено;

		Читатель = Новый ЧтениеТекста;
		Читатель.Открыть(ВремПутьРезультатаРаспознавания);
		Пока Истина Цикл
	
			Стр = Читатель.ПрочитатьСтроку();
			Если Стр = Неопределено Тогда
				Прервать;
			КонецЕсли;
	
			Если ПустаяСтрока(Стр) Тогда
				Продолжить;
			КонецЕсли;

			Стр = СокрЛП(Стр);

			Если ЭтоНомерСтиха(Стр) Тогда
				НомерСтиха = Стр;
				Прервать;
			КонецЕсли;

			СообщениеОтладки("--> Это не номер стиха: " + Стр + ". Пропускаем.");

		КонецЦикла;

		Если НомерСтиха = Неопределено Тогда
			СообщениеОтладки("--> Номер стиха не удалось определить");
			Продолжить;
		КонецЕсли;

		СообщениеОтладки("--> Получен номер стиха: " + НомерСтиха);

		Если Не ЭтоРежимОтладки() Тогда
			Сообщить(СтрШаблон("%1	%2", ФайлКартинки.Имя, НомерСтиха));
		КонецЕсли;

	КонецЦикла;

КонецФункции

Функция РеСовпадает(Паттерн, Строка)
	РегВыражение = Новый РегулярноеВыражение(Паттерн);
	Возврат РегВыражение.Совпадает(Строка);
КонецФункции

Функция ЭтоНомерСтиха(Строка)
	Возврат РеСовпадает("\d+\-\d+", Строка);
КонецФункции

Функция ФайлСуществует(ПолныйПуть)
	Файл = Новый Файл(ПолныйПуть);
	Возврат Файл.Существует();
КонецФункции

Функция ЭтоРежимОтладки()
	Возврат РежимОтладки = Истина;
КонецФункции

Функция СообщениеОтладки(ТекстСообщения)
	Если ЭтоРежимОтладки() Тогда
		Сообщить(ТекстСообщения);
	КонецЕсли;
КонецФункции

Функция ВыполнитьКоманду(СтрКоманда)

	Процесс = СоздатьПроцесс(СтрКоманда,,Истина);
	Процесс.Запустить();
	Процесс.ОжидатьЗавершения();

КонецФункции

РежимОтладки = Истина;

КаталогСтихов = "/home/kuntashov/poetry/03";

ОбработатьФайлы(КаталогСтихов);