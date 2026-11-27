package se.kth.iv1351.view;

import java.util.ArrayList;
import java.util.List;

public class CommandLine {
    public List<String> values;
    
    public CommandLine(String line){
        values = readLine(line);
    }

    public String getCommand(){
        if (values.size() >= 1){
            return values.get(0);
        }
        return "";
    }

    public List<String> getArguments(){
        if (values.size() >= 2){
            return values.subList(1, values.size());
        }
        return new ArrayList<>();
    }

    private static List<String> readLine(String line){
        List<String> values = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        char quote = 0;
        boolean escaped = false;
        boolean tokenStarted = false;

        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (escaped) {
                switch (c) {
                    case 'n' -> current.append('\n');
                    case 't' -> current.append('\t');
                    case '\\' -> current.append('\\');
                    case '\'' -> current.append('\'');
                    case '"' -> current.append('"');
                    default -> current.append(c);
                }
                escaped = false;
                tokenStarted = true;
                continue;
            } 
            if (quote != 0) {
                if (c == '\\') {
                    escaped = true;
                    tokenStarted = true;
                    continue;
                }
                if (c == quote) {
                    quote = 0;
                } else {
                    current.append(c);
                }
                tokenStarted = true;
                continue;
            }
            if (c == '"' || c == '\'') {
                quote = c;
                tokenStarted = true;
                continue;
            }
            if (c == ' ' || c == '\t' || c == '\n') {
                if (tokenStarted) {
                    values.add(current.toString());
                    current.setLength(0);
                    tokenStarted = false;
                }
                continue;
            }
            current.append(c);
            tokenStarted = true;
        }

        if (escaped) {
            current.append('\\');
        }
        if (tokenStarted) {
            values.add(current.toString());
        }
        if (quote != 0) {
            throw new IllegalArgumentException("Unclosed quote");
        }
        return values;
    }
}
