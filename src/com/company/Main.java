package com.company;

import java.io.*;

public class Main {
    
    public static void main(String[] args) {
        try (BufferedWriter writer = new BufferedWriter(new FileWriter("dmlScript.txt"))) {
            Generator generator = new Generator(writer);
            generator.generate();
            writer.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
