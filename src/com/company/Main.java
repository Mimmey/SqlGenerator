package com.company;

import java.io.*;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.concurrent.ThreadLocalRandom;

public class Main {
    private final static String DATE_FORMATTER = "yyyy-MM-dd";
    /**
     * 1: DELETED
     * 2: AUTO
     * users: 3 .. usersCount
     * monsters: usersCount + 1 .. usersCount + monstersCount
     * torturedSouls: usersCount + monstersCount + 1 .. usersCount + monstersCount + torturedSoulsCount + 1
     * workingSouls: usersCount + monstersCount + torturedSoulsCount + 1 .. personIdCount
     */

    private static int eventsCount = 0;
    private static int monstersCount = 0;
    private static int personIdCount = 0;
    private static int sinTypesCount = 0;
    private static int tartarLevelLocationsCount = 0;
    private static int torturesCount = 0;
    private static int torturedSoulsCount = 0;
    private static int usersCount = 0;
    private static int worksCount = 0;

    public static String formatDate(LocalDate date) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern(DATE_FORMATTER);
        return date.format(formatter);
    }

    public static String generateDate(String startDate, String endDate) {
        long minDay = LocalDate.parse(startDate).toEpochDay();
        long maxDay = LocalDate.parse(endDate).toEpochDay();
        long randomDay = ThreadLocalRandom.current().nextLong(minDay, maxDay);
        LocalDate randomDate = LocalDate.ofEpochDay(randomDay);
        return formatDate(randomDate);
    }

    public static int generateNumber(int from, int to) {
        return (int) (from + Math.round(Math.random() * (to - from)));
    }

    public static int getHandlerId() {
        return generateNumber(3, usersCount);
    }

    public static int getLocationId() {
        return generateNumber(1, tartarLevelLocationsCount);
    }

    public static int getMonsterId() {
        return generateNumber(usersCount + 1, usersCount + monstersCount);
    }

    public static int getTorturedSoulId() {
        return generateNumber(monstersCount + monstersCount + 1, usersCount + monstersCount + torturedSoulsCount + 1);
    }

    public static int getWorkingSoulId() {
        return generateNumber(monstersCount + monstersCount + torturedSoulsCount + 1, personIdCount);
    }

    public static int getTortureId() {
        return generateNumber(1, torturesCount);
    }

    public static int getSinTypeId() {
        return generateNumber(1, sinTypesCount);
    };

    public static double getWeight() {
        return Math.random();
    }

    public static int getWorkId() {
        return generateNumber(1, worksCount);
    };

    public static void generateComplaints(BufferedWriter writer) throws IOException {
        String[] titles = new String[]{"Перевод на работу", "Смена пытки", "Перерождение"};
        String[] bodies = new String[]{"Переведите меня, пожалуйста, на работу", "Смените мне пытку, пожалуйста", "Переродите меня, пожалуйста"};

        for (int i = 0; i < titles.length; i++) {
            String title = titles[i];
            String body = bodies[i];
            int soulId = getTorturedSoulId();
            int statusId = generateNumber(0, 1) == 0 ? 1 : 3;
            int handlerId = getHandlerId();
            writer.write(String.format("INSERT INTO complaint (title, body, soul_id, status_id, handler_id) VALUES ('%s', '%s', %d, %d, %d);\n", title, body, soulId, statusId, handlerId));
        }
    }

    public static void generateEvents(BufferedWriter writer) throws IOException {
        String[] actionList = new String[]{"Убил", "Сбил", "Украл", "Избил", "Сбросил со скалы", "Съел", "Замучил", "Ударил", "Оклеветал", "Держал в заложниках"};
        String[] subjectList = new String[]{"консьержку", "знакомую", "знакомого", "собаку", "одногруппника", "жену", "прохожего", "соседа", "друга", "брата"};
        String[] conditionList = new String[]{"с особой жестокостью", "не единожды", "будучи принужденным", "будучи в состоянии алкогольного опьянения", "будучи в состоянии наркотического опьянения", "будучи в состоянии аффекта", "и скрылся с места преступления", "и пришел с повинной", "и был пойман с поличным", "и понес наказание в виде лишения свободы"};

        for (String action : actionList) {
            for (String subject : subjectList) {
                for (String condition : conditionList) {
                    String crime = action + " " + subject + " " + condition;
                    int soulId = getTorturedSoulId();
                    String date = generateDate("1943-01-01", "1973-01-01");
                    int statusId = 1;
                    int handlerId = getHandlerId();
                    writer.write(String.format("INSERT INTO _event (_text, soul_id, _date, status_id, handler_id) VALUES ('%s', %d, '%s', %d, %d);\n", crime, soulId, date, statusId, handlerId));
                    eventsCount++;
                }
            }
        }
    }

    public static void generateWorks(BufferedWriter writer) throws IOException {
        String[] works = new String[]{"Шут", "Лекарь", "Добытчик серебра", "Стеркорариус", "Переносчик людей",
                                        "Гимназиарх", "Создатель табличек с проклятьями", "Похоронный клоун",
                                        "Пращик", "Водный органист", "Летописец", "Бард"};

        for (String i : works) {
            int locationId = getLocationId();
            int creatorId = getHandlerId();
            writer.write(String.format("INSERT INTO work (_name, location_id, creator_id) VALUES ('%s', %d, %d);\n", i, locationId, creatorId));
            worksCount++;
        }
    }

    public static void generateLevels(BufferedWriter writer) throws IOException {
        writer.write("INSERT INTO _level (_name) VALUES ('Тартар');\n");
        writer.write("INSERT INTO _level (_name) VALUES ('Асфоделевый луг');\n");
        writer.write("INSERT INTO _level (_name) VALUES ('Элизиум');\n");
    }

    public static void generateLocations(BufferedWriter writer) throws IOException {
        String[] tartarLocations = new String[]{"Река страданий", "Лес ужаса", "Озеро страха", "Пещера мучений", "Море пыток"};

        for (String location : tartarLocations) {
            int levelId = 1;
            writer.write(String.format("INSERT INTO _location (_name, level_id) VALUES ('%s', %d);\n", location, levelId));
            tartarLevelLocationsCount++;
        }

        String[] asphodelLocations = new String[]{"Поле сомнений", "Река печали", "Лес разочарований", "Степь тоски", "Болото горечи"};

        for (String location : asphodelLocations) {
            int levelId = 2;
            writer.write(String.format("INSERT INTO _location (_name, level_id) VALUES ('%s', %d);\n", location, levelId));
        }

        String[] elysiumLocations = new String[]{"Лес сказок", "Поле чудес", "Море радости", "Озеро спокойствия", "Дорога добра"};

        for (String location : elysiumLocations) {
            int levelId = 3;
            writer.write(String.format("INSERT INTO _location (_name, level_id) VALUES ('%s', %d);\n", location, levelId));
        }
    }

    public static void generateMonsters(BufferedWriter writer) throws IOException {
        String[] monsters = new String[]{"Алекто", "Мегера", "Тисифона", "Лернейская Гидра", "Ехидна", "Герион", "Пифон"};

        for (String i : monsters) { // 8 .. 14
            int locationId = getLocationId();
            int motherlandId = getLocationId();
            writer.write("INSERT INTO person (_name) VALUES ('" + i + "');\n");
            writer.write(String.format("INSERT INTO monster (person_id, location_id, motherland_id) VALUES (%d, %d, %d);\n", ++personIdCount, locationId, motherlandId));
            monstersCount++;
        }
    }

    public static void generateSinTypeDistributionList(BufferedWriter writer) throws IOException {
        for (int i = 0; i < eventsCount; i++) {
            int eventId = i + 1;
            int sinTypeId = getSinTypeId();

            writer.write(String.format("INSERT INTO sin_type_distribution_list (event_id, sin_type_id) VALUES (%d, %d);\n", eventId, sinTypeId));
        }
    }

    public static void generateSinTypes(BufferedWriter writer) throws IOException {
        String[] sinTypes = new String[]{"Убийство", "Воровство", "Военное преступление", "Профессиональное преступление",
                                        "Рецидивистское преступление", "Вымогательство", "Хулиганство",
                                        "Доведение до самоубийства", "Хулиганство", "Похищение человека",
                                        "Террористический акт", "жестокое обращение с животными", "Клевета", "Побои",
                                        "Причинение тяжкого вреда здоровью"};

        for (String i : sinTypes) {
            double weight = getWeight();
            String weightString = String.format(Locale.US, "%.10f", weight);
            int handlerId = getHandlerId();
            int creatorId = getHandlerId();
            int tortureId = getTortureId();
            writer.write(String.format("INSERT INTO sin_type (_name, _weight, creator_id, handler_id, torture_id) VALUES ('%s', %s, %d, %d, %d);\n", i, weightString, creatorId, handlerId, tortureId));
            sinTypesCount++;
        }
    }

    public static void generateSouls(BufferedWriter writer) throws IOException {
        String[] nameList = new String[]{"Иван", "Дмитрий", "Николай", "Сергей", "Глеб", "Борис", "Денис", "Валерий", "Мирослав", "Григорий", "Артемий", "Виталий", "Александр", "Алексей"};
        String[] torturedMenSurnameList = new String[]{"Иванов", "Шигалев", "Григорьев", "Краснов", "Белов", "Кроваткин", "Стулович", "Красочников", "Вернандский", "Чопорев", "Трубчанский", "Туманов", "Тучников", "Капотников"};
        String[] workingMenSurnameList = new String[]{"Чуков", "Геков", "Сланцев", "Тихомиров", "Чукотский", "Корышкин", "Лебедев", "Ларченко", "Круглёныш", "Ножница", "Лимонченко", "Сташевский"};
        String[] fatherNameList = new String[]{"Иванович", "Дмитриевич", "Николаевич", "Сергеевич", "Глебович", "Борисович", "Денисович", "Валерьевич", "Мирославович", "Григорьевич", "Артемьевич", "Витальевич", "Александрович", "Алексеевич"};

        for (String i : nameList) {
            for (String j : torturedMenSurnameList) {
                for (String k : fatherNameList) {
                    String dateOfBirth = generateDate("1903-01-01", "1923-01-01");
                    String dateOfDeath = generateDate("1973-01-01", "2022-01-01");
                    boolean isWorking = false;
                    boolean isDistributed = true;
                    int handlerId = getHandlerId();
                    int tortureId = getTortureId();
                    writer.write(String.format("INSERT INTO person (_name) VALUES ('%s %s %s');\n", i, k, j));
                    writer.write(String.format("INSERT INTO soul (person_id, birth_date, date_of_death, is_working, is_distributed, handler_id, torture_id) VALUES (%d, '%s', '%s', %b, %b, %d, %d);\n", ++personIdCount, dateOfBirth, dateOfDeath, isWorking, isDistributed, handlerId, tortureId));
                    torturedSoulsCount++;
                }
            }
        }

        for (String i : nameList) {
            for (String j : workingMenSurnameList) {
                for (String k : fatherNameList) {
                    String dateOfBirth = generateDate("1903-01-01", "1923-01-01");
                    String dateOfDeath = generateDate("1973-01-01", "2022-01-01");
                    boolean isWorking = true;
                    boolean isDistributed = true;
                    int handlerId = getHandlerId();
                    int tortureId = getTortureId();
                    writer.write(String.format("INSERT INTO person (_name) VALUES ('%s %s %s');\n", i, k, j));
                    writer.write(String.format("INSERT INTO soul (person_id, birth_date, date_of_death, is_working, is_distributed, handler_id, torture_id) VALUES (%d, '%s', '%s', %b, %b, %d, %d);\n", ++personIdCount, dateOfBirth, dateOfDeath, isWorking, isDistributed, handlerId, tortureId));
                }
            }
        }
    }

    public static void generateStatuses(BufferedWriter writer) throws IOException {
        String[] statuses = new String[]{"Не обработано", "Одобрено", "Отказано"};

        for (String i : statuses) {
            writer.write(String.format("INSERT INTO _status (_name) VALUES ('%s');\n", i));
        }
    }

    public static void generateTortures(BufferedWriter writer) throws IOException {
        String[] tortures = new String[]{"Бесконечное наполнение бездонной бочки", "Разрыв внутренних органов", "Башмаки с шипом",
                                        "Вилка еретика", "Кресло для ведьминого купания", "Испанский сапог", "Пытка водой",
                                        "Кошачий коготь", "Дыба", "Четвертование лошадьми", "Груша", "Очищение души",
                                        "Пресс для черепа", "Колыбель Иуды", "Железная дева", "Кол", "Пила"};

        for (String i : tortures) {
            int creatorId = getHandlerId();
            int handlerId = getHandlerId();
            int monsterId = getMonsterId();
            writer.write(String.format("INSERT INTO torture (_name, monster_id, creator_id, handler_id) VALUES ('%s', %d, %d, %d);\n", i, monsterId, creatorId, handlerId));
            torturesCount++;
        }
    }

    public static void generateUsers(BufferedWriter writer) throws IOException {
        String[] users = new String[]{"DELETED", "AUTO", "Аид", "Персефона", "Эак", "Радамант", "Минос"};

        for (String i : users) {
            writer.write(String.format("INSERT INTO person (_name) VALUES ('%s');\n", i));
            writer.write(String.format("INSERT INTO _user (person_id) VALUES (%d);\n", ++personIdCount));
            usersCount++;
        }
    }

    public static void generateWorkList(BufferedWriter writer) throws IOException {
        int amount = generateNumber(100, 500);

        for (int i = 0; i < amount; i++) {
            int soulId = getWorkingSoulId();
            int workId = getWorkId();

            writer.write(String.format("INSERT INTO work_list (soul_id, work_id) VALUES (%d, %d);\n", soulId, workId));
        }
    }

    public static void main(String[] args) {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter("dmlScript.txt"))) {
            generateUsers(writer);
            generateLevels(writer);
            generateLocations(writer);
            generateMonsters(writer);
            generateTortures(writer);
            generateSouls(writer);
            generateSinTypes(writer);
            generateStatuses(writer);
            generateComplaints(writer);
            generateEvents(writer);
            generateWorks(writer);
            generateSinTypeDistributionList(writer);
            generateWorkList(writer);
            writer.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
