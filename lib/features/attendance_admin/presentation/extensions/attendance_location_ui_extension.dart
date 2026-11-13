/// "25 m", "100 m", "1 km".
String formatAttendanceRadius(int metres) =>
    metres == 1000 ? '1 km' : '$metres m';
