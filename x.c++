// Create a class Point with x and y.
//  Then create a class Line that has:
//  • Two fields: start and end (both Point type)
//  • A method print() that prints the line coordinates
//  • A method move(double dx, double dy) that shifts both points.
#include <iostream>
using namespace std;
class Point{
public:
    int x, y;
    Point():x(0),y(0){}
    Point(int a, int b):x(a),y(b){}
};
class Line{
    private:
        Point start, end;
    public:
        Line(Point p1, Point p2){
            start = p1;
            end = p2;
        }
        void print(){
            cout << "Line from (" << start.x << ", " << start.y << ") "
             << "to (" << end.x << ", " << end.y << ")" << endl;
        }
        void move(double dx, double dy){
            start.x += dx;
            start.y += dy;
            end.x += dx;
            end.y += dy;
        }
};
int main(){
    Point point1(3,8);
    Point point2(4,9);
    Line line(point1, point2);
    line.print();
}