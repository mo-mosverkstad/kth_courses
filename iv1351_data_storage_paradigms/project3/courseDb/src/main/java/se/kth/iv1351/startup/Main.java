package se.kth.iv1351.startup;

import se.kth.iv1351.controller.CourseDBController;
import se.kth.iv1351.view.BasicView;

public class Main {
    public static void main(String[] args){
        try{
            new BasicView(new CourseDBController()).start();
        }
        catch (RuntimeException exception){
            System.out.println("--- Startup errors ---");
            exception.printStackTrace();
            System.out.println("--- ---");
        }
    }
}
