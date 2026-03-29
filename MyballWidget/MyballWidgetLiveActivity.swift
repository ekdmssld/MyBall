//
//  MyballWidgetLiveActivity.swift
//  MyballWidget
//
//  Created by 정다은 on 3/23/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MyballWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MyballWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MyballWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MyballWidgetAttributes {
    fileprivate static var preview: MyballWidgetAttributes {
        MyballWidgetAttributes(name: "World")
    }
}

extension MyballWidgetAttributes.ContentState {
    fileprivate static var smiley: MyballWidgetAttributes.ContentState {
        MyballWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MyballWidgetAttributes.ContentState {
         MyballWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MyballWidgetAttributes.preview) {
   MyballWidgetLiveActivity()
} contentStates: {
    MyballWidgetAttributes.ContentState.smiley
    MyballWidgetAttributes.ContentState.starEyes
}
