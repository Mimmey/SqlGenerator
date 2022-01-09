package com.company;

import java.io.BufferedWriter;
import java.io.IOException;
import java.util.Locale;

public class Generator {
    /**
     * 1: DELETED
     * 2: AUTO
     * users: 3 .. usersCount
     * monsters: usersCount + 1 .. usersCount + monstersCount
     * torturedSouls: usersCount + monstersCount + 1 .. usersCount + monstersCount + torturedSoulsCount
     * workingSouls: usersCount + monstersCount + torturedSoulsCount + 1 .. workingSouls: usersCount + monstersCount + torturedSoulsCount + workingSoulsCount
     * nonDistributedSouls: workingSouls: usersCount + monstersCount + torturedSoulsCount + workingSoulsCount .. personIdCount
     * */

    /**
     * distributedEvents: 1 .. distributedEventsCount
     * nonDistributedEvents: distributedEventsCount + 1 .. eventsCount
     * */

    private BufferedWriter writer;
    private static int eventsCount = 0;
    private static int distributedEventsCount = 0;
    private static int locationsCount = 0;
    private static int monstersCount = 0;
    private static int personIdCount = 0;
    private static int sinTypesCount = 0;
    private static int tartarLevelLocationsCount = 0;
    private static int torturesCount = 0;
    private static int torturedSoulsCount = 0;
    private static int usersCount = 0;
    private static int worksCount = 0;
    private static int workingSoulsCount = 0;

    public Generator(BufferedWriter writer) {
        this.writer = writer;
    }

    public void generate() throws IOException {
        generateUsers();
        generateLevels();
        generateLocations();
        generateMonsters();
        generateTortures();
        generateSouls();
        generateSinTypes();
        generateStatuses();
        generateComplaints();
        generateEvents();
        generateWorks();
        generateSinTypeDistributionList();
        generateWorkList();
    }

    public void generateComplaints() throws IOException {
        String[] titles = new String[]{"Перевод на работу", "Смена пытки", "Перерождение", "Большая просьба", "Меня замучали!"};
        String[] bodies = new String[]{"Переведите меня, пожалуйста, на работу", "Смените мне пытку, пожалуйста", "Переродите меня, пожалуйста", "Я очень устал, дайте мне работу вместо пытки", "Пожалуйста, увольте моего монстра, он делает то, что мне не назначено!"};

        int amount = Randomizer.getNumber(100, 500);

        for (int i = 0; i < amount; i++) {
            int index = Randomizer.getNumber(0, titles.length - 1);
            String title = titles[index];
            String body = bodies[index];
            int soulId = Randomizer.getTorturedSoulId(usersCount, monstersCount, torturedSoulsCount);
            int statusId = 1;
            writer.write(String.format("INSERT INTO complaint (title, body, soul_id, status_id) VALUES ('%s', '%s', %d, %d);\n", title, body, soulId, statusId));
        }
    }

    public void generateEvents() throws IOException {
        String[] actionList = new String[]{"Убил", "Сбил", "Похитил", "Избил", "Сбросил со скалы", "Довел до самоубийства", "Замучил", "Ударил", "Застрелил", "Держал в заложниках"};
        String[] subjectDistributedList = new String[]{"консьержку", "знакомую", "знакомого", "собаку", "одногруппника", "жену", "прохожего", "соседа", "друга", "брата"};
        String[] subjectNonDistributedList = new String[]{"кошку", "тещу", "тестя", "сестру", "двоюродную сестру", "племянницу", "бездомного", "коллегу", "начальника", "племянника"};
        String[] conditionList = new String[]{"с особой жестокостью", "не единожды", "будучи принужденным", "будучи в состоянии алкогольного опьянения", "будучи в состоянии наркотического опьянения", "будучи в состоянии аффекта", "и скрылся с места преступления", "и пришел с повинной", "и был пойман с поличным", "и понес наказание в виде лишения свободы"};

        for (String action : actionList) {
            for (String subject : subjectDistributedList) {
                for (String condition : conditionList) {
                    String crime = action + " " + subject + " " + condition;
                    int soulId = Randomizer.getTorturedSoulId(usersCount, monstersCount, torturedSoulsCount);
                    String date = Randomizer.getDate("1943-01-01", "1973-01-01");
                    int statusId = 2;
                    int handler_id = Randomizer.getHandlerId(usersCount);
                    writer.write(String.format("INSERT INTO _event (_text, soul_id, _date, status_id, handler_id) VALUES ('%s', %d, '%s', %d, %d);\n", crime, soulId, date, statusId, handler_id));
                    eventsCount++;
                    distributedEventsCount++;
                }
            }
        }

        for (String action : actionList) {
            for (String subject : subjectNonDistributedList) {
                for (String condition : conditionList) {
                    String crime = action + " " + subject + " " + condition;
                    int soulId = Randomizer.getTorturedSoulId(usersCount, monstersCount, torturedSoulsCount);
                    String date = Randomizer.getDate("1943-01-01", "1973-01-01");
                    int statusId = 1;
                    writer.write(String.format("INSERT INTO _event (_text, soul_id, _date, status_id) VALUES ('%s', %d, '%s', %d);\n", crime, soulId, date, statusId));
                    eventsCount++;
                }
            }
        }
    }

    public void generateWorks() throws IOException {
        String[] works = new String[]{"Шут", "Лекарь", "Добытчик серебра", "Стеркорариус", "Переносчик людей",
                "Гимназиарх", "Создатель табличек с проклятьями", "Похоронный клоун",
                "Пращик", "Водный органист", "Летописец", "Бард"};

        for (String i : works) {
            int locationId = Randomizer.getNotTartarLocationId(tartarLevelLocationsCount, locationsCount);
            int creatorId = Randomizer.getHandlerId(usersCount);
            this.writer.write(String.format("INSERT INTO work (_name, location_id, creator_id) VALUES ('%s', %d, %d);\n", i, locationId, creatorId));
            worksCount++;
        }
    }

    public void generateLevels() throws IOException {
        writer.write("INSERT INTO _level (_name) VALUES ('Тартар');\n");
        writer.write("INSERT INTO _level (_name) VALUES ('Асфоделевый луг');\n");
        writer.write("INSERT INTO _level (_name) VALUES ('Элизиум');\n");
    }

    public void generateLocations() throws IOException {
        String[] tartarLocations = new String[]{"Река страданий", "Лес ужаса", "Озеро страха", "Пещера мучений", "Море пыток"};

        for (String location : tartarLocations) {
            int levelId = 1;
            writer.write(String.format("INSERT INTO _location (_name, level_id) VALUES ('%s', %d);\n", location, levelId));
            tartarLevelLocationsCount++;
            locationsCount++;
        }

        String[] asphodelLocations = new String[]{"Поле сомнений", "Река печали", "Лес разочарований", "Степь тоски", "Болото горечи"};

        for (String location : asphodelLocations) {
            int levelId = 2;
            writer.write(String.format("INSERT INTO _location (_name, level_id) VALUES ('%s', %d);\n", location, levelId));
            locationsCount++;
        }

        String[] elysiumLocations = new String[]{"Лес сказок", "Поле чудес", "Море радости", "Озеро спокойствия", "Дорога добра"};

        for (String location : elysiumLocations) {
            int levelId = 3;
            writer.write(String.format("INSERT INTO _location (_name, level_id) VALUES ('%s', %d);\n", location, levelId));
            locationsCount++;
        }
    }

    public void generateMonsters() throws IOException {
        String[] monsters = new String[]{"Алекто", "Мегера", "Тисифона", "Лернейская Гидра", "Ехидна", "Герион", "Пифон"};

        for (String i : monsters) { // 8 .. 14
            int locationId = Randomizer.getTartarLocationId(tartarLevelLocationsCount);
            int motherlandId = Randomizer.getTartarLocationId(tartarLevelLocationsCount);
            writer.write("INSERT INTO person (_name) VALUES ('" + i + "');\n");
            writer.write(String.format("INSERT INTO monster (person_id, location_id, motherland_id) VALUES (%d, %d, %d);\n", ++personIdCount, locationId, motherlandId));
            monstersCount++;
        }
    }

    public void generateSinTypeDistributionList() throws IOException {
        for (int i = 0; i < distributedEventsCount; i++) {
            int eventId = i + 1;
            int sinTypeId = Randomizer.getSinTypeId(sinTypesCount);

            writer.write(String.format("INSERT INTO sin_type_distribution_list (event_id, sin_type_id) VALUES (%d, %d);\n", eventId, sinTypeId));
        }
    }

    public void generateSinTypes() throws IOException {
        String[] sinTypes = new String[]{"Убийство", "Воровство", "Военное преступление", "Профессиональное преступление",
                "Рецидивистское преступление", "Вымогательство", "Хулиганство",
                "Доведение до самоубийства", "Похищение человека",
                "Террористический акт", "жестокое обращение с животными", "Клевета", "Побои",
                "Причинение тяжкого вреда здоровью"};

        for (String i : sinTypes) {
            double weight = Randomizer.getWeight();
            String weightString = String.format(Locale.US, "%.10f", weight);
            int handlerId = Randomizer.getHandlerId(usersCount);
            int creatorId = Randomizer.getHandlerId(usersCount);
            int tortureId = Randomizer.getTortureId(torturesCount);
            writer.write(String.format("INSERT INTO sin_type (_name, _weight, creator_id, handler_id, torture_id) VALUES ('%s', %s, %d, %d, %d);\n", i, weightString, creatorId, handlerId, tortureId));
            sinTypesCount++;
        }
    }

    public void generateSouls() throws IOException {
        String[] nameList = new String[]{"Иван", "Дмитрий", "Николай", "Сергей", "Глеб", "Борис", "Денис", "Валерий", "Мирослав", "Григорий", "Артемий", "Виталий", "Александр", "Алексей"};
        String[] torturedMenSurnameList = new String[]{"Иванов", "Шигалев", "Григорьев", "Краснов", "Белов", "Кроваткин", "Стулович", "Красочников", "Вернандский", "Чопорев", "Трубчанский", "Туманов", "Тучников", "Капотников"};
        String[] workingMenSurnameList = new String[]{"Чуков", "Геков", "Сланцев", "Тихомиров", "Чукотский", "Корышкин", "Лебедев", "Ларченко", "Круглёныш", "Ножница", "Лимонченко", "Сташевский"};
        String[] nonDistributedMenSurnameList = new String[]{"Пух", "Рыжов", "Чмок", "Кряк", "Кройченко", "Пекаревский", "Кисловязов", "Собирович", "Дровосековский", "Лукич", "Застекайло", "Многокриков"};
        String[] fatherNameList = new String[]{"Иванович", "Дмитриевич", "Николаевич", "Сергеевич", "Глебович", "Борисович", "Денисович", "Валерьевич", "Мирославович", "Григорьевич", "Артемьевич", "Витальевич", "Александрович", "Алексеевич"};

        for (String i : nameList) {
            for (String j : torturedMenSurnameList) {
                for (String k : fatherNameList) {
                    String dateOfBirth = Randomizer.getDate("1903-01-01", "1923-01-01");
                    String dateOfDeath = Randomizer.getDate("1973-01-01", "2022-01-01");
                    boolean isWorking = false;
                    boolean isDistributed = true;
                    int handlerId = Randomizer.getHandlerId(usersCount);
                    int tortureId = Randomizer.getTortureId(torturesCount);
                    writer.write(String.format("INSERT INTO person (_name) VALUES ('%s %s %s');\n", i, k, j));
                    writer.write(String.format("INSERT INTO soul (person_id, birth_date, date_of_death, is_working, is_distributed, handler_id, torture_id) VALUES (%d, '%s', '%s', %b, %b, %d, %d);\n", ++personIdCount, dateOfBirth, dateOfDeath, isWorking, isDistributed, handlerId, tortureId));
                    torturedSoulsCount++;
                }
            }
        }

        for (String i : nameList) {
            for (String j : workingMenSurnameList) {
                for (String k : fatherNameList) {
                    String dateOfBirth = Randomizer.getDate("1903-01-01", "1923-01-01");
                    String dateOfDeath = Randomizer.getDate("1973-01-01", "2022-01-01");
                    boolean isWorking = true;
                    boolean isDistributed = true;
                    int handlerId = Randomizer.getHandlerId(usersCount);
                    int tortureId = Randomizer.getTortureId(torturesCount);
                    writer.write(String.format("INSERT INTO person (_name) VALUES ('%s %s %s');\n", i, k, j));
                    writer.write(String.format("INSERT INTO soul (person_id, birth_date, date_of_death, is_working, is_distributed, handler_id, torture_id) VALUES (%d, '%s', '%s', %b, %b, %d, %d);\n", ++personIdCount, dateOfBirth, dateOfDeath, isWorking, isDistributed, handlerId, tortureId));
                    workingSoulsCount++;
                }
            }
        }

        for (String i : nameList) {
            for (String j : nonDistributedMenSurnameList) {
                for (String k : fatherNameList) {
                    String dateOfBirth = Randomizer.getDate("1903-01-01", "1923-01-01");
                    String dateOfDeath = Randomizer.getDate("1973-01-01", "2022-01-01");
                    boolean isWorking = false;
                    boolean isDistributed = false;
                    int tortureId = Randomizer.getTortureId(torturesCount);
                    writer.write(String.format("INSERT INTO person (_name) VALUES ('%s %s %s');\n", i, k, j));
                    writer.write(String.format("INSERT INTO soul (person_id, birth_date, date_of_death, is_working, is_distributed, torture_id) VALUES (%d, '%s', '%s', %b, %b, %d);\n", ++personIdCount, dateOfBirth, dateOfDeath, isWorking, isDistributed, tortureId));
                }
            }
        }
    }

    public void generateStatuses() throws IOException {
        String[] statuses = new String[]{"Не обработано", "Одобрено", "Отказано"};

        for (String i : statuses) {
            writer.write(String.format("INSERT INTO _status (_name) VALUES ('%s');\n", i));
        }
    }

    public void generateTortures() throws IOException {
        String[] tortures = new String[]{"Бесконечное наполнение бездонной бочки", "Разрыв внутренних органов", "Башмаки с шипом",
                "Вилка еретика", "Кресло для ведьминого купания", "Испанский сапог", "Пытка водой",
                "Кошачий коготь", "Дыба", "Четвертование лошадьми", "Груша", "Очищение души",
                "Пресс для черепа", "Колыбель Иуды", "Железная дева", "Кол", "Пила"};

        for (String i : tortures) {
            int creatorId = Randomizer.getHandlerId(usersCount);
            int handlerId = Randomizer.getHandlerId(usersCount);
            int monsterId = Randomizer.getMonsterId(usersCount, monstersCount);
            writer.write(String.format("INSERT INTO torture (_name, monster_id, creator_id, handler_id) VALUES ('%s', %d, %d, %d);\n", i, monsterId, creatorId, handlerId));
            torturesCount++;
        }
    }

    public void generateUsers() throws IOException {
        String[] users = new String[]{"DELETED", "AUTO", "UNAUTHORIZED", "Аид", "Персефона", "Эак", "Радамант", "Минос"};

        for (String i : users) {
            writer.write(String.format("INSERT INTO person (_name) VALUES ('%s');\n", i));
            writer.write(String.format("INSERT INTO _user (person_id) VALUES (%d);\n", ++personIdCount));
            usersCount++;
        }
    }

    public void generateWorkList() throws IOException {
        for (int i = 0; i < workingSoulsCount; i++) {
            int soulId = i + usersCount + monstersCount + torturedSoulsCount + 1;
            int workId = Randomizer.getWorkId(worksCount);

            writer.write(String.format("INSERT INTO work_list (soul_id, work_id) VALUES (%d, %d);\n", soulId, workId));
        }
    }
}
