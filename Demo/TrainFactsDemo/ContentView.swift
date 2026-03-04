//  Copyright (C) 2025 DB Fernverkehr AG.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


import SwiftUI
import DBScrollingTabPager

enum Tab: DBTab {
    case tab1
    case tab2
    case tab3
    
    var label: String {
        switch self {
        case .tab1: String(localized: "ICE1")
        case .tab2: String(localized: "ICE2")
        case .tab3: String(localized: "ICE3")
        }
    }
}

struct ContentView: View {
    @State var selection: Tab? = nil
    @State var headerOpacity: CGFloat = 1.0
    var body: some View {
        NavigationStack {
            ZStack {
                DBScrollingTabPager(tabs: [Tab.tab1, .tab2, .tab3],
                                    selection: $selection,
                                    headerOpacity: $headerOpacity) {
                    
                    // The header which will be scrolled over by the tab view
                    ZStack(alignment: .center) {
                        Color.clear.ignoresSafeArea()
                        Image("icesmall").resizable().aspectRatio(contentMode: .fit).frame(height: 100)
                    }.padding()
                } background: {
                    // The background extending into the safe area
                    LinearGradient(colors: [Color("DB Red 400"), Color("DB Red 800")],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                } tabLabelProvider: { context in
                    // Provides the text view for an individual tab label
                    Text(context.tab.label)
                            .font(context.isSelected ? .headline : .body)
                            .tint(.primary)
                } pages: {
                    // The pages in order of display from left to right, which should correspond to the items in the "tabs" array
                    PageOne()
                    PageTwo()
                    PageThree()
                }.scrollingTabPagerStyle(.init(standardTabPagerBackgroundColor: .init(UIColor.systemBackground),
                                               stuckTabPagerBackgroundColor: .init(UIColor.secondarySystemBackground),
                                               contentBackgroundColor: .init(UIColor.systemBackground),
                                               dividerColor: .gray,
                                               topCornerRadius: 8))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Testing") { }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("Train Facts").foregroundStyle(.white)
                            .opacity(1 - headerOpacity)
                    }
                }.navigationBarTitleDisplayMode(.inline)
                
            }
        }
    }
}

struct PageOne: View {
    var body: some View {
        VStack {
            Text("""
                ICE 1 trains consist of two powerheads and 9 to 14 intermediate cars. Because trainsets are not separated in regular service, they can be seen as multiple units from an operational point of view. During the first refurbishment, which was completed in late 2008, trainsets were standardized to 12 intermediate cars.

                Until the first refurbishment was completed, there had been three different configurations of ICE 1 trainsets:

                Refurbished trainsets consist of two power cars and 12 intermediate cars. These include four first class cars, including the service car with the conductors' compartment (numbered 9, 11, 12, 14), one restaurant car (8) and seven second class cars (1 to 7).[4] Smoking is prohibited in all cars. Cars 1, 3, 9, 11 and 14 are equipped with cellular repeaters.
                Non-refurbished trainsets for domestic service consisted of three first class cars (11, 12 and 14), seven second class cars (1 to 7), a service car (9) and a restaurant car (10). Car number 7 might have been one of three types: an original second class car of the ICE 1, a second-class-car from the ICE 2 or a first class car from the ICE 1, marked as second class. The first class car number 13 was removed; this was one of two first class cars for smokers, but without the additional equipment of car 14 (video, telephone)[5]
                Non-refurbished trainsets for service into Switzerland consisted of four first class cars (11 to 14) and six second class cars (1 to 6) plus a service and a restaurant (9 and 10)
                A train consisting of 14 cars had a length of 410.70 metres (1,347 ft 5 in). Prior to the refurbishment this train would have had 192 seats in first class, 567 seats in second class and 40 seats in the restaurant car plus four in the conference compartment. Two spaces for wheelchairs are available.[4]

                Most cars of the ICE 1 offer both compartments and rows of seats, just like the seating in German InterCity cars.[4] Cars at the ends of the trainsets used to be smoking areas. There are "quiet" cars as well as cars that were later equipped with cell phone repeaters.[6] Some seats were designed to turn to face the direction of travel, but this was never used in revenue service.[4]
                """)
        }.padding()
    }
}

struct PageTwo: View {
    var body: some View {
        VStack {
            Text("""
The ICE 2 is the second series of German high-speed trains and one of six in the Intercity-Express family since 1995. The ICE 2 (half-) trains are even closer to a conventional push–pull train than the ICE 1, because each train consists of only one locomotive (Class 402, called powerhead), six passenger cars (Classes 805 to 807) and a cab car (Class 808). The maximum speed is 280 km/h (175 mph), but this is limited to 250 km/h (155 mph) when the cab car is leading the train and even further down to 160 km/h (100 mph) when two units are coupled at the powerheads due to the forces on the overhead line by their respective pantographs.                
""")
        }.padding()
    }
}

struct PageThree: View {
    var body: some View {
        VStack {
            Text("""
                The design goal of the ICE 3 (Class 403) was to create a higher-powered, lighter train than its predecessors such as the ICE 2 and the ICE 1. This was achieved by distributing its 16 traction motors underneath the whole train, thus ICE 3 trains are Electric multiple units (EMUs). The train is certified for 330 km/h (210 mph) and has reached 368 km/h (229 mph) on trial runs. On regular Intercity-Express services they run at up to 300 km/h (190 mph), the maximum design speed of German high-speed lines.

                Because the train does not have power cars, the whole length of the train is available for passenger seats, including the first car. The lounge seats are located directly behind the driver, separated only by a glass wall.

                The 50 sets were ordered in 1994 and specifically designed for the new high-speed line between Frankfurt and Cologne. They were built by a consortium led by Siemens and Adtranz (which became Bombardier Transportation).[4]

                For the EXPO 2000 in Hanover, Deutsche Bahn provided 120 additional train services. Some of these special services were operated by ICE trains and labelled "ExpoExpress" (EXE). These services also constituted the first widespread use of the then-new ICE 3 train sets, presenting them to the domestic and international general public.[5]

                On 11 April 2017, Deutsche Bahn announced the modernisation programme called ICE 3 Redesign for its 66-unit ICE 3 fleet to be completed by the end of 2020.[6] The renovation involves replacing the seats, tables, and floor coverings. The six-seat compartment rooms are eliminated from the second class section to increase the number of seats and add more luggage compartments. In addition, the number of disability seating has been increased to two; however, no integrated wheelchair lift has been installed, and no disability seating is offered in the first-class section. The seats in some Bordrestaurant have been converted to the red bench seating while Bordbistro receives the new stand tables. The cabin illumination is provided by LED lamps, providing more illumination, while the reading lamps are eliminated. The seat reservation panels are moved from the walls above the windows to the seat headrests per EU directive on accessibilities: the new panel has bigger and more visible white lettering and Braille. The yellow LCD information monitors in the antechambers are replaced with larger full-colour LED displays, showing the map, train number, speed, and other pertinent information. The new smaller displays are attached to the ceiling above the aisle throughout the cabins.
                """)
        }.padding()
    }
}
#Preview {
    ContentView()
}
