package se.kth.iv1351.view;

import se.kth.iv1351.controller.CourseDBController;

public class BasicView implements View {
    private final CourseDBController controller;

    public BasicView(CourseDBController controller){
        this.controller = controller;
    }

    public void start(){
        System.out.println("Basic view started!");
    }
}
