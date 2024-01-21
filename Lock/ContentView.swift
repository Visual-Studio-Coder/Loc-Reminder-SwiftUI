//
//  ContentView.swift
//  Lock
//
//  Created by Vaibhav Satishkumar on 4/25/23.
//

import SwiftUI
import CoreLocation





struct ContentView: View {
    
	
    
    @Environment(\.managedObjectContext) var moc
    
    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spots>
    
   
    
    var body: some View {
        
		
		
		
		
			TabView{
				SpotNotificationLogger()
					.tabItem {
						Image(systemName: "list.bullet.rectangle")
						Text("Logs")
					}
				SpotBrowser()
					.tabItem {
						Image(systemName: "mappin.circle.fill")
						Text("Spots")
					}
				InfoTab()
					.tabItem {
						Image(systemName: "info.circle.fill")
						Text("About")
					}
			}
		
    }
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        
        
        
        ContentView()
       
     
    }
}
     



extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
