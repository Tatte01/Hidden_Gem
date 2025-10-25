# Repport Bok

## 2025-09-01

I spent today figuring out and downloading flutter and getting it all to work.
I got it to work to the point i can run a small program and for now i got in in chrome.

for next time i would like to get it on a moblie machine. i did get the mobile machine to work but i need it to work with the test app.

## 2025-09-03

to start the emulator is 
- cd /mnt/c/Users/malte/Documents/GitHub/personal_project
- flutter devices
- flutter emulators --launch Pixel_5
- flutter run

I got it up an running with updates with capital R

Now i need to learn a little bit more about the dart langue. On first glance it looks like Java Script.
Widgest is basicly elements of the app.

Important things to remeber about.
Widget is basicly elements of the app.

Today i went over alot of basic funcsions of the flutter/ dart langue 
i will continue to do so next time hopeing i will learn more.
I also want to look more in to the Firebase for backend 

https://firebase.google.com

### Shortcuts
R - To refresh the page to get the updates.
P - is to see the overlat of the app in the same way as you can do if you inspect where the things are.
I - is to the Widgets.

### Now to the .dart it self.

#### Rows and Colums
body : Row to have them in rows.

body : colums to have it in colums.

```
try body: Row(
    children: [
    Icon(Icons.backpack),
    Icon(Icons.leaderboard),
    Icon(Icons.person)
    ],
),
```

#### Stack.

The stack is for when you for example want to make a button you stack the text on the button.
```
body: Stack(
    children: [
    Container(),
    Icon(Icons.verified)
    ],
),
```

#### Posisions 

Positioned = absolute posision in css.

Align = we want to posision it acording to its parrent we can use align.


#### BottomNavigasionBarItem
It needs atlest 2 Items.
````
bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.grey,
          items: const [
            BottomNavigationBarItem
          (icon: Icon(Icons.home),
          label: 'Home',
          ),
          BottomNavigationBarItem
          (icon: Icon(Icons.business),
          label: 'Work',
          ),
        ]),
````

#### floatingActionButton

```
floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
            onPressed: () {
              print("obje½!t");
            },
          ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.grey,
          items: const [
            BottomNavigationBarItem
          (icon: Icon(Icons.home),
          label: 'Home',
          ),
          BottomNavigationBarItem
          (icon: Icon(Icons.business),
          label: 'Work',
          ),
        ]),

```

#### Drawer

```
drawer: Drawer(
          child: Text('Yo'),
        ),
```

#### Builder

Builders is a funcsion that for example keeps creating backround coolors. it makes the app more dynamic.

```
body : ListView.builder(
    itemBuilder: (_, index) {
        return Container(
            color:randomColor(),
            width:500,
            height : 500,
        );
    },
),
```

#### Random Color

```
Color getRandomColor() {
    return Color(Random().nextInt(0xFFFFFFFF)).withOpacity(1.0);
}
```


#### Goggle maps

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => _MapSampleState();
}

class _MapSampleState extends State<MapSample> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(56.1625, 15.5801);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
    );
  }
}
## 2025-09-09

Styles

ShadowColor
elevation


Patch = updates given field but lleaves the other ones open.
Put = updates the fields given and removes everything else.

## After this is just random thinkgs that i used over the project.

THIS DOES NOT MEAN EVERYTHING I USED IN THE PROJECT IS HERE JUST MEANS THAT THE THINGS THAT ARE HERE I MIGHT HAVE USED.

for research only


### Profile page

### Friednds Page

### MapScreen

### Gem screen

#### ListView

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: data.length,
      itemBuilder: (context, index) {
        String key = data.keys.elementAt(index);
        var item = data[key];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['Name'] ?? 'No Name',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Description: ${item['Decoration']}'),
                Text('Latitude: ${item['Latitude']}'),
                Text('Longitude: ${item['Longitude']}'),
                Text('Updated: ${item['lastUpdated']}'),
              ],
            ),
          ),
        );
      },
    ),
  );
}