
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

struct WorldSystem
{
    static bool loadingWorld;

    static void setNumExpectedEntities(int num);
    static void triggerReceivedEntity();
};

