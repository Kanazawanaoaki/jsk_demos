from collections import OrderedDict

import torch
import torchvision
from torchvision.models.detection import FasterRCNN
from torchvision.models.detection.rpn import AnchorGenerator


def get_model_rpn(num_classes, pretrained_model=None,
                  aspect_ratios=(0.6, 1.0, 1.6)):
    backbone = torchvision.models.mobilenet_v2(pretrained=True).features
    backbone.out_channels = 1280
    anchor_generator = AnchorGenerator(sizes=((32, 64, 128, 256, 512),),
                                       aspect_ratios=(aspect_ratios,))
    # put the pieces together inside a FasterRCNN model
    model = FasterRCNN(backbone,
                       num_classes=num_classes,
                       rpn_anchor_generator=anchor_generator)

    if pretrained_model is not None:
        state_dict = torch.load(pretrained_model,
                                map_location='cpu')
        new_state_dict = OrderedDict()
        for k, v in state_dict.items():
            new_state_dict[k.lstrip('module.')] = v
        model.load_state_dict(new_state_dict)
    return model
