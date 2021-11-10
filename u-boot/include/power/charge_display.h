/*
 * (C) Copyright 2017 Rockchip Electronics Co., Ltd
 *
 * SPDX-License-Identifier:     GPL-2.0+
 */

#ifndef _CHARGE_DISPLAY_H_
#define _CHARGE_DISPLAY_H_

struct dm_charge_display_ops {
	int (*show)(struct udevice *dev);
};

int charge_display(void);

#endif
