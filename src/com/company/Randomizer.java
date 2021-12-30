package com.company;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.ThreadLocalRandom;

public class Randomizer {
    private final static String DATE_FORMATTER = "yyyy-MM-dd";

    public static String formatDate(LocalDate date) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern(DATE_FORMATTER);
        return date.format(formatter);
    }

    public static String getDate(String startDate, String endDate) {
        long minDay = LocalDate.parse(startDate).toEpochDay();
        long maxDay = LocalDate.parse(endDate).toEpochDay();
        long randomDay = ThreadLocalRandom.current().nextLong(minDay, maxDay);
        LocalDate randomDate = LocalDate.ofEpochDay(randomDay);
        return formatDate(randomDate);
    }

    public static int getNumber(int from, int to) {
        return (int) (from + Math.round(Math.random() * (to - from)));
    }

    public static int getHandlerId(int usersCount) {
        return getNumber(3, usersCount);
    }

    public static int getTartarLocationId(int tartarLevelLocationsCount) {
        return getNumber(1, tartarLevelLocationsCount);
    }

    public static int getNotTartarLocationId(int tartarLevelLocationsCount, int locationsCount) {
        return getNumber(tartarLevelLocationsCount + 1, locationsCount);
    }

    public static int getMonsterId(int usersCount, int monstersCount) {
        return getNumber(usersCount + 1, usersCount + monstersCount);
    }

    public static int getTorturedSoulId(int usersCount, int monstersCount, int torturedSoulsCount) {
        return getNumber(usersCount + monstersCount + 1, usersCount + monstersCount + torturedSoulsCount + 1);
    }

    public static int getWorkingSoulId(int usersCount, int monstersCount, int torturedSoulsCount, int personIdCount) {
        return getNumber(usersCount + monstersCount + torturedSoulsCount + 1, personIdCount);
    }

    public static int getTortureId(int torturesCount) {
        return getNumber(1, torturesCount);
    }

    public static int getSinTypeId(int sinTypesCount) {
        return getNumber(1, sinTypesCount);
    };

    public static double getWeight() {
        return Math.random();
    }

    public static int getWorkId(int worksCount) {
        return getNumber(1, worksCount);
    };
}
