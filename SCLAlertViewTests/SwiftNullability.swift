import UIKit

@MainActor
func checkNullablePresentationInputs(
    alert: SCLAlertView,
    windowAlert: SCLAlertView,
    host: UIViewController
) {
    alert.showWarning(host, title: nil, subTitle: "Cancel appointment?", closeButtonTitle: "No", duration: 0)
    windowAlert.showWarning(nil, subTitle: nil, closeButtonTitle: "No", duration: 0)
    alert.showCustom(host, image: nil, color: nil, title: "Duplicate goal", subTitle: nil, closeButtonTitle: "Cancel", duration: 0)
    windowAlert.showCustom(nil, color: nil, title: "Duplicate goal", subTitle: nil, closeButtonTitle: "Cancel", duration: 0)

    let builder = SCLAlertViewShowBuilder()
    _ = builder.image(nil).color(nil).title(nil).subTitle(nil)
}
